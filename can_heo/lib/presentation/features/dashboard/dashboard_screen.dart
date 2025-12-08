import 'package:flutter/material.dart';

// Import các màn hình con
import '../market_export/market_export_screen.dart';
import '../history/invoice_history_screen.dart';
import '../partners/partners_screen.dart';
import '../pig_types/pig_types_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ==============================
          // 1. MENU BÊN TRÁI (NavigationRail)
          // ==============================
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            // Thêm padding để menu thoáng hơn
            groupAlignment: -0.9, 
            destinations: const [
              // Index 0
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Tổng quan'),
              ),
              // Index 1
              NavigationRailDestination(
                icon: Icon(Icons.output_outlined),
                selectedIcon: Icon(Icons.output),
                label: Text('Xuất Chợ'),
              ),
              // Index 2
              NavigationRailDestination(
                icon: Icon(Icons.input_outlined),
                selectedIcon: Icon(Icons.input),
                label: Text('Nhập Kho'),
              ),
              // Index 3
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Đối tác'),
              ),
              // Index 4: Loại heo management
              NavigationRailDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: Text('Loại heo'),
              ),
              // Index 4: THÊM NÚT LỊCH SỬ VÀO ĐÂY
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Lịch sử'),
              ),
            ],
          ),
          
          // Đường kẻ dọc phân cách
          const VerticalDivider(thickness: 1, width: 1),

          // ==============================
          // 2. MÀN HÌNH NỘI DUNG BÊN PHẢI
          // ==============================
          Expanded(
            child: _buildBody(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const Center(child: Text("Màn hình Thống kê (Coming Soon)"));
      case 1:
        return const MarketExportScreen(); // Màn hình Xuất Chợ
      case 2:
        return const Center(child: Text("Màn hình NHẬP KHO (Sẽ làm tiếp theo)"));

      case 3:
         return const PartnersScreen();
      case 4:
        // Gọi màn hình quản lý Loại heo
        return const PigTypesScreen();
      case 5:
        // Gọi màn hình Lịch sử với type = 2 (Xuất Chợ)
        return const InvoiceHistoryScreen(invoiceType: 2);
      default:
        return const SizedBox();
    }
  }
}