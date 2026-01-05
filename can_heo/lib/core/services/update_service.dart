import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service quản lý việc kiểm tra và cập nhật ứng dụng từ GitHub Releases
/// 
/// Quy trình:
/// 1. Kiểm tra GitHub Releases API
/// 2. So sánh với version hiện tại
/// 3. Nếu có bản mới -> tải file Setup.exe
/// 4. Chạy installer và tắt app
class UpdateService {
  /// Thông tin GitHub Repository - THAY ĐỔI THEO REPO CỦA BẠN
  static const String githubOwner = 'tranminhieu10';
  static const String githubRepo = 'can_heo';
  
  /// URL GitHub API
  static String get _apiUrl => 
    'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  
  /// Version hiện tại của app (cập nhật khi build mới)
  static const String currentVersion = '1.0.6';
  
  /// Build number hiện tại
  static const int currentBuildNumber = 6;

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

  /// Kiểm tra có bản cập nhật mới không từ GitHub Releases
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      status.value = UpdateStatus.checking;
      errorMessage.value = null;

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(_apiUrl));
      request.headers.add('Accept', 'application/vnd.github.v3+json');
      request.headers.add('User-Agent', 'CanHeo-App');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('GitHub API trả về lỗi: ${response.statusCode}');
      }

      final jsonString = await response.transform(utf8.decoder).join();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      httpClient.close();

      // Parse thông tin từ GitHub Release
      final tagName = (json['tag_name'] as String? ?? 'v1.0.0').replaceAll('v', '');
      final releaseNotes = json['body'] as String? ?? '';
      final publishedAt = json['published_at'] as String?;
      
      // Tìm file installer trong assets
      String? downloadUrl;
      int fileSize = 0;
      final assets = json['assets'] as List? ?? [];
      
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        // Tìm file .exe Setup
        if (name.toLowerCase().contains('setup') && name.endsWith('.exe')) {
          downloadUrl = asset['browser_download_url'] as String?;
          fileSize = asset['size'] as int? ?? 0;
          break;
        }
      }
      
      // Nếu không tìm thấy Setup, tìm file .exe bất kỳ
      if (downloadUrl == null) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.exe')) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileSize = asset['size'] as int? ?? 0;
            break;
          }
        }
      }

      latestUpdate = UpdateInfo(
        version: tagName,
        buildNumber: 1,
        downloadUrl: downloadUrl ?? '',
        releaseNotes: releaseNotes,
        fileSize: fileSize,
        releaseDate: publishedAt != null ? DateTime.parse(publishedAt) : DateTime.now(),
        forceUpdate: releaseNotes.toLowerCase().contains('[force]'),
      );

      // So sánh version
      final hasUpdate = _compareVersions(currentVersion, latestUpdate!.version) < 0;

      status.value = UpdateStatus.idle;

      if (hasUpdate && downloadUrl != null) {
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
    if (latestUpdate == null || latestUpdate!.downloadUrl.isEmpty) {
      errorMessage.value = 'Không tìm thấy file cập nhật';
      return false;
    }

    try {
      status.value = UpdateStatus.downloading;
      downloadProgress.value = 0.0;
      errorMessage.value = null;

      // Lấy thư mục Temp từ biến môi trường (không dùng path_provider)
      final tempPath = Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? 'C:\\Temp';
      final installerPath = '$tempPath\\CanHeo_Setup_${latestUpdate!.version}.exe';
      final installerFile = File(installerPath);

      // Xóa file cũ nếu có
      if (await installerFile.exists()) {
        await installerFile.delete();
      }

      // Tải file từ GitHub
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(latestUpdate!.downloadUrl));
      request.headers.add('User-Agent', 'CanHeo-App');
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

      // Chạy installer (Inno Setup với /SILENT)
      await Process.start(
        installerPath, 
        ['/SILENT', '/CLOSEAPPLICATIONS'],
        mode: ProcessStartMode.detached,
      );

      status.value = UpdateStatus.completed;

      // Tắt app sau 2 giây để installer chạy
      await Future.delayed(const Duration(seconds: 2));
      exit(0);

    } catch (e) {
      status.value = UpdateStatus.error;
      errorMessage.value = 'Lỗi cài đặt: $e';
      return false;
    }
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
