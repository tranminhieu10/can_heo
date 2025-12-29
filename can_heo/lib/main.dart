import 'package:flutter/material.dart';

import 'core/utils/responsive.dart';
import 'core/services/license_service.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'domain/repositories/i_user_repository.dart';
import 'presentation/features/auth/login_screen.dart';
import 'presentation/features/dashboard/dashboard_screen.dart';
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
      // Hiển thị cảnh báo nếu sắp hết hạn
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
