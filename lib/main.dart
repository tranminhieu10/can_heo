import 'package:flutter/material.dart';

// Import file injection vừa tạo
import 'injection_container.dart' as di;

// Import màn hình Dashboard (Bạn đảm bảo đã tạo file này ở bước trước)
import 'presentation/features/dashboard/dashboard_screen.dart';

void main() async {
  // Đảm bảo Flutter Binding được khởi tạo trước khi làm bất cứ việc gì asynchronous
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection (Database, Repos, Blocs...)
  await di.init();

  // Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phần mềm Cân Heo', // Tên hiển thị trên thanh taskbar
      debugShowCheckedModeBanner: false, // Tắt chữ debug góc phải
      
      // Cấu hình Theme (Màu sắc chủ đạo)
      theme: ThemeData(
        // Dùng màu Teal (xanh cổ vịt) hoặc Blue tùy sở thích của bạn
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        
        // Cấu hình font chữ hoặc style mặc định cho các thành phần khác tại đây
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      
      // Màn hình đầu tiên khi mở app
      home: const DashboardScreen(),
    );
  }
}