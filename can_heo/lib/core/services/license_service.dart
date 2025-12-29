import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// License Service - Quản lý license phần mềm
/// 
/// Cách hoạt động:
/// 1. Tạo Machine ID từ hardware của máy khách
/// 2. Khách gửi Machine ID cho bạn
/// 3. Bạn tạo License Key và gửi lại cho khách
/// 4. App kiểm tra License Key mỗi lần khởi động
class LicenseService {
  static const String _secretKey = 'CAN_HEO_2025_SECRET_KEY_CHANGE_THIS';
  static const String _licenseFileName = 'license.key';
  
  static LicenseService? _instance;
  static LicenseService get instance => _instance ??= LicenseService._();
  
  LicenseService._();
  
  LicenseInfo? _cachedLicense;
  
  /// Lấy Machine ID của máy hiện tại
  Future<String> getMachineId() async {
    try {
      if (Platform.isWindows) {
        // Lấy thông tin từ nhiều nguồn để tạo ID duy nhất
        final results = await Future.wait([
          _runCommand('wmic', ['csproduct', 'get', 'uuid']),
          _runCommand('wmic', ['cpu', 'get', 'processorid']),
          _runCommand('wmic', ['baseboard', 'get', 'serialnumber']),
        ]);
        
        final combined = results.join('|');
        final bytes = utf8.encode(combined + _secretKey);
        final hash = sha256.convert(bytes);
        
        // Lấy 16 ký tự đầu, chia thành 4 nhóm
        final shortHash = hash.toString().substring(0, 16).toUpperCase();
        return '${shortHash.substring(0, 4)}-${shortHash.substring(4, 8)}-${shortHash.substring(8, 12)}-${shortHash.substring(12, 16)}';
      }
      return 'UNSUPPORTED-PLATFORM';
    } catch (e) {
      // Fallback: sử dụng tên máy tính
      try {
        final hostname = Platform.localHostname;
        final bytes = utf8.encode(hostname + _secretKey);
        final hash = sha256.convert(bytes);
        final shortHash = hash.toString().substring(0, 16).toUpperCase();
        return '${shortHash.substring(0, 4)}-${shortHash.substring(4, 8)}-${shortHash.substring(8, 12)}-${shortHash.substring(12, 16)}';
      } catch (_) {
        return 'ERROR-MACHINE-ID';
      }
    }
  }
  
  Future<String> _runCommand(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);
      return result.stdout.toString().trim();
    } catch (e) {
      return '';
    }
  }
  
  /// Tạo License Key (CHỈ DÙNG PHÍA ADMIN/BẠN)
  /// [machineId] - Machine ID của khách
  /// [expiryDate] - Ngày hết hạn
  /// [customerName] - Tên khách hàng
  static String generateLicenseKey({
    required String machineId,
    required DateTime expiryDate,
    required String customerName,
    LicenseType type = LicenseType.trial,
  }) {
    final data = {
      'mid': machineId,
      'exp': expiryDate.toIso8601String(),
      'name': customerName,
      'type': type.index,
      'created': DateTime.now().toIso8601String(),
    };
    
    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64Encode(bytes);
    
    // Tạo signature
    final signatureBytes = utf8.encode(base64Str + _secretKey);
    final signature = sha256.convert(signatureBytes).toString().substring(0, 8).toUpperCase();
    
    return '$base64Str.$signature';
  }
  
  /// Xác thực License Key
  Future<LicenseResult> validateLicense() async {
    try {
      final licenseKey = await _readLicenseFile();
      
      if (licenseKey == null || licenseKey.isEmpty) {
        return LicenseResult(
          isValid: false,
          status: LicenseStatus.notFound,
          message: 'Chưa có license. Vui lòng liên hệ để kích hoạt phần mềm.',
        );
      }
      
      // Parse license key
      final parts = licenseKey.split('.');
      if (parts.length != 2) {
        return LicenseResult(
          isValid: false,
          status: LicenseStatus.invalid,
          message: 'License không hợp lệ.',
        );
      }
      
      final base64Str = parts[0];
      final signature = parts[1];
      
      // Verify signature
      final expectedSigBytes = utf8.encode(base64Str + _secretKey);
      final expectedSig = sha256.convert(expectedSigBytes).toString().substring(0, 8).toUpperCase();
      
      if (signature != expectedSig) {
        return LicenseResult(
          isValid: false,
          status: LicenseStatus.tampered,
          message: 'License đã bị chỉnh sửa. Vui lòng liên hệ hỗ trợ.',
        );
      }
      
      // Decode data
      final jsonStr = utf8.decode(base64Decode(base64Str));
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final licenseMachineId = data['mid'] as String;
      final expiryDate = DateTime.parse(data['exp'] as String);
      final customerName = data['name'] as String;
      final licenseType = LicenseType.values[data['type'] as int];
      
      // Check machine ID
      final currentMachineId = await getMachineId();
      if (licenseMachineId != currentMachineId) {
        return LicenseResult(
          isValid: false,
          status: LicenseStatus.wrongMachine,
          message: 'License không dành cho máy này.\nMachine ID hiện tại: $currentMachineId',
        );
      }
      
      // Check expiry
      if (DateTime.now().isAfter(expiryDate)) {
        return LicenseResult(
          isValid: false,
          status: LicenseStatus.expired,
          message: 'License đã hết hạn vào ngày ${_formatDate(expiryDate)}.\nVui lòng gia hạn để tiếp tục sử dụng.',
          info: LicenseInfo(
            customerName: customerName,
            expiryDate: expiryDate,
            machineId: licenseMachineId,
            type: licenseType,
          ),
        );
      }
      
      // Calculate days remaining
      final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
      
      _cachedLicense = LicenseInfo(
        customerName: customerName,
        expiryDate: expiryDate,
        machineId: licenseMachineId,
        type: licenseType,
        daysRemaining: daysRemaining,
      );
      
      String message = 'License hợp lệ - $customerName';
      if (daysRemaining <= 7) {
        message += '\n⚠️ Còn $daysRemaining ngày sử dụng!';
      }
      
      return LicenseResult(
        isValid: true,
        status: LicenseStatus.valid,
        message: message,
        info: _cachedLicense,
      );
    } catch (e) {
      return LicenseResult(
        isValid: false,
        status: LicenseStatus.error,
        message: 'Lỗi kiểm tra license: $e',
      );
    }
  }
  
  /// Lưu license key vào file
  Future<bool> saveLicenseKey(String licenseKey) async {
    try {
      final file = await _getLicenseFile();
      await file.writeAsString(licenseKey.trim());
      _cachedLicense = null; // Clear cache
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Xóa license (khi cần reset)
  Future<bool> removeLicense() async {
    try {
      final file = await _getLicenseFile();
      if (await file.exists()) {
        await file.delete();
      }
      _cachedLicense = null;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<File> _getLicenseFile() async {
    // Sử dụng LOCALAPPDATA trực tiếp thay vì path_provider
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final appDir = Directory('$localAppData\\can_heo');
    
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return File('${appDir.path}\\$_licenseFileName');
  }
  
  Future<String?> _readLicenseFile() async {
    try {
      final file = await _getLicenseFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Lấy thông tin license đã cache
  LicenseInfo? get currentLicense => _cachedLicense;
}

enum LicenseType {
  trial,      // Dùng thử
  standard,   // Bản thường
  premium,    // Bản cao cấp
  lifetime,   // Vĩnh viễn
}

enum LicenseStatus {
  valid,
  notFound,
  invalid,
  expired,
  wrongMachine,
  tampered,
  error,
}

class LicenseResult {
  final bool isValid;
  final LicenseStatus status;
  final String message;
  final LicenseInfo? info;
  
  LicenseResult({
    required this.isValid,
    required this.status,
    required this.message,
    this.info,
  });
}

class LicenseInfo {
  final String customerName;
  final DateTime expiryDate;
  final String machineId;
  final LicenseType type;
  final int daysRemaining;
  
  LicenseInfo({
    required this.customerName,
    required this.expiryDate,
    required this.machineId,
    required this.type,
    this.daysRemaining = 0,
  });
  
  String get typeDisplayName {
    switch (type) {
      case LicenseType.trial:
        return 'Dùng thử';
      case LicenseType.standard:
        return 'Tiêu chuẩn';
      case LicenseType.premium:
        return 'Cao cấp';
      case LicenseType.lifetime:
        return 'Vĩnh viễn';
    }
  }
}
