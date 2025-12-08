import 'package:flutter/material.dart';

import 'injection_container.dart' as di;
import 'presentation/features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
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

    return MaterialApp(
      title: 'Cân Heo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const DashboardScreen(),
    );
  }
}
