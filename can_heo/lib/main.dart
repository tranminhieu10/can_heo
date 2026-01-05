import 'dart:io';
import 'package:flutter/material.dart';

import 'core/utils/responsive.dart';
import 'core/services/license_service.dart';
import 'core/services/update_service.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'domain/repositories/i_user_repository.dart';
import 'presentation/features/auth/login_screen.dart';
import 'presentation/features/license/license_activation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Tạo tài khoản admin mặc định nếu chưa có
  final userRepo = sl<IUserRepository>();
  await userRepo.createDefaultAdmin();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cân Heo',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      builder: (context, child) {
        // Initialize responsive utility
        Responsive.init(context);
        
        // Apply text scaling based on screen size
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(Responsive.textScaleFactor),
          ),
          child: child ?? const SizedBox(),
        );
      },
      home: const LicenseCheckWrapper(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// Widget kiểm tra License khi khởi động app
class LicenseCheckWrapper extends StatefulWidget {
  const LicenseCheckWrapper({super.key});

  @override
  State<LicenseCheckWrapper> createState() => _LicenseCheckWrapperState();
}

class _LicenseCheckWrapperState extends State<LicenseCheckWrapper> {
  bool _isChecking = true;
  bool _isLicenseValid = false;
  LicenseResult? _licenseResult;
  bool _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    final result = await LicenseService.instance.validateLicense();
    
    setState(() {
      _isChecking = false;
      _isLicenseValid = result.isValid;
      _licenseResult = result;
    });
  }

  /// Kiểm tra cập nhật tự động khi khởi động
  Future<void> _checkForUpdates() async {
    // Chỉ kiểm tra trên Windows
    if (!Platform.isWindows) return;
    
    // Chỉ kiểm tra 1 lần khi app khởi động
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    try {
      final updateService = UpdateService();
      final result = await updateService.checkForUpdates();
      
      if (result.hasUpdate && mounted) {
        _showUpdateDialog(result, updateService);
      }
    } catch (e) {
      // Im lặng nếu có lỗi kiểm tra cập nhật
      debugPrint('Lỗi kiểm tra cập nhật: $e');
    }
  }

  void _showUpdateDialog(UpdateCheckResult result, UpdateService updateService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(
        result: result,
        updateService: updateService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đang kiểm tra license
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang kiểm tra license...'),
            ],
          ),
        ),
      );
    }

    // License hợp lệ → vào app
    if (_isLicenseValid) {
      // Hiển thị cảnh báo nếu sắp hết hạn + kiểm tra cập nhật
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Kiểm tra cập nhật tự động
        _checkForUpdates();
        
        // Cảnh báo license sắp hết hạn
        if (_licenseResult?.info != null && 
            _licenseResult!.info!.daysRemaining <= 7 &&
            _licenseResult!.info!.daysRemaining > 0) {
          _showExpiryWarning();
        }
      });
      return const LoginScreen();
    }

    // License không hợp lệ → màn hình kích hoạt
    return LicenseActivationScreen(
      onActivated: () {
        setState(() {
          _isLicenseValid = true;
        });
      },
    );
  }

  void _showExpiryWarning() {
    final days = _licenseResult!.info!.daysRemaining;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('License sắp hết hạn'),
          ],
        ),
        content: Text(
          'License của bạn sẽ hết hạn sau $days ngày.\n'
          'Vui lòng liên hệ để gia hạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

/// Dialog thông báo cập nhật
class _UpdateDialog extends StatefulWidget {
  final UpdateCheckResult result;
  final UpdateService updateService;

  const _UpdateDialog({
    required this.result,
    required this.updateService,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    // Lắng nghe tiến trình download
    widget.updateService.downloadProgress.addListener(_onProgressChanged);
    widget.updateService.status.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    widget.updateService.downloadProgress.removeListener(_onProgressChanged);
    widget.updateService.status.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    setState(() {
      _downloadProgress = widget.updateService.downloadProgress.value;
      final percent = (_downloadProgress * 100).toStringAsFixed(0);
      _statusText = 'Đang tải: $percent%';
    });
  }

  void _onStatusChanged() {
    final status = widget.updateService.status.value;
    setState(() {
      switch (status) {
        case UpdateStatus.downloading:
          _isDownloading = true;
          _statusText = 'Đang tải xuống...';
          break;
        case UpdateStatus.installing:
          _statusText = 'Đang cài đặt...';
          break;
        case UpdateStatus.completed:
          _statusText = 'Hoàn tất! Đang khởi động lại...';
          break;
        case UpdateStatus.error:
          _isDownloading = false;
          _statusText = widget.updateService.errorMessage.value ?? 'Có lỗi xảy ra';
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.system_update, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Có bản cập nhật mới!'),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phiên bản hiện tại',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          widget.result.currentVersion,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Phiên bản mới',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          widget.result.newVersion,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Release notes
            if (widget.result.releaseNotes != null && widget.result.releaseNotes!.isNotEmpty) ...[
              const Text(
                'Nội dung cập nhật:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.result.releaseNotes!,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ),
            ],
            
            // Download progress
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Để sau'),
          ),
          ElevatedButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Cập nhật ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: null,
            child: Text(_statusText.contains('Đang') ? 'Đang xử lý...' : 'Vui lòng đợi'),
          ),
        ],
      ],
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Đang chuẩn bị...';
    });

    // Sử dụng downloadAndInstall có sẵn trong UpdateService
    await widget.updateService.downloadAndInstall();
  }
}
