import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service quản lý việc kiểm tra và cập nhật ứng dụng
/// 
/// Quy trình:
/// 1. Check version từ server (version.json)
/// 2. So sánh với version hiện tại
/// 3. Nếu có bản mới -> tải file .msi
/// 4. Chạy installer và tắt app
class UpdateService {
  /// URL tới file version.json trên server
  /// Thay đổi URL này theo hosting của bạn
  static const String versionUrl = 'https://your-server.com/updates/version.json';
  
  /// Version hiện tại của app (lấy từ pubspec.yaml)
  static const String currentVersion = '1.0.0';
  
  /// Build number hiện tại
  static const int currentBuildNumber = 1;

  /// Singleton instance
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Trạng thái download
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<UpdateStatus> status = ValueNotifier(UpdateStatus.idle);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Thông tin bản cập nhật mới (nếu có)
  UpdateInfo? latestUpdate;

  /// Kiểm tra có bản cập nhật mới không
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      status.value = UpdateStatus.checking;
      errorMessage.value = null;

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(versionUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }

      final jsonString = await response.transform(utf8.decoder).join();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      latestUpdate = UpdateInfo.fromJson(json);
      httpClient.close();

      // So sánh version
      final hasUpdate = _compareVersions(currentVersion, latestUpdate!.version) < 0 ||
          (currentVersion == latestUpdate!.version && currentBuildNumber < latestUpdate!.buildNumber);

      status.value = UpdateStatus.idle;

      if (hasUpdate) {
        return UpdateCheckResult(
          hasUpdate: true,
          currentVersion: currentVersion,
          newVersion: latestUpdate!.version,
          releaseNotes: latestUpdate!.releaseNotes,
          downloadSize: latestUpdate!.fileSize,
        );
      } else {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          newVersion: currentVersion,
        );
      }
    } catch (e) {
      status.value = UpdateStatus.error;
      errorMessage.value = 'Lỗi kiểm tra cập nhật: $e';
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        error: e.toString(),
      );
    }
  }

  /// Tải và cài đặt bản cập nhật
  Future<bool> downloadAndInstall() async {
    if (latestUpdate == null) {
      errorMessage.value = 'Chưa kiểm tra cập nhật';
      return false;
    }

    try {
      status.value = UpdateStatus.downloading;
      downloadProgress.value = 0.0;
      errorMessage.value = null;

      // Lấy thư mục Temp
      final tempDir = await getTemporaryDirectory();
      final installerPath = '${tempDir.path}\\can_heo_${latestUpdate!.version}.msix';
      final installerFile = File(installerPath);

      // Xóa file cũ nếu có
      if (await installerFile.exists()) {
        await installerFile.delete();
      }

      // Tải file
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(latestUpdate!.downloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Không thể tải file: ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final sink = installerFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (totalBytes > 0) {
          downloadProgress.value = receivedBytes / totalBytes;
        }
      }

      await sink.close();
      httpClient.close();

      status.value = UpdateStatus.installing;

      // Chạy installer
      // Với MSIX, dùng PowerShell Add-AppxPackage
      final result = await Process.run(
        'powershell',
        [
          '-ExecutionPolicy', 'Bypass',
          '-Command',
          'Add-AppxPackage -Path "$installerPath" -ForceApplicationShutdown'
        ],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        // Nếu MSIX không hoạt động, thử mở file để user tự cài
        await Process.run('explorer', [installerPath]);
      }

      status.value = UpdateStatus.completed;

      // Tắt app sau 2 giây
      await Future.delayed(const Duration(seconds: 2));
      exit(0);

    } catch (e) {
      status.value = UpdateStatus.error;
      errorMessage.value = 'Lỗi cài đặt: $e';
      return false;
    }

    return true;
  }

  /// So sánh 2 version string (vd: "1.0.0" vs "1.0.1")
  /// Returns: -1 nếu v1 < v2, 0 nếu bằng, 1 nếu v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }
}

/// Trạng thái của quá trình cập nhật
enum UpdateStatus {
  idle,
  checking,
  downloading,
  installing,
  completed,
  error,
}

/// Thông tin bản cập nhật từ server
class UpdateInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final int fileSize; // bytes
  final DateTime releaseDate;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.releaseDate,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      downloadUrl: json['download_url'] as String,
      releaseNotes: json['release_notes'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      releaseDate: DateTime.tryParse(json['release_date'] ?? '') ?? DateTime.now(),
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }
}

/// Kết quả kiểm tra cập nhật
class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String newVersion;
  final String? releaseNotes;
  final int? downloadSize;
  final String? error;

  UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.newVersion,
    this.releaseNotes,
    this.downloadSize,
    this.error,
  });
}
