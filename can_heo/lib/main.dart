import 'package:flutter/material.dart';

import 'core/utils/responsive.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'domain/repositories/i_user_repository.dart';
import 'presentation/features/auth/login_screen.dart';
import 'presentation/features/dashboard/dashboard_screen.dart';

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
      home: const LoginScreen(),
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
