import 'package:flutter/material.dart';
import '../market_export/market_export_screen.dart';

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
          // 1. Menu bên trái (NavigationRail chuẩn Desktop)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Tổng quan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.output), // Icon xuất
                label: Text('Xuất Chợ'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.input), // Icon nhập
                label: Text('Nhập Kho'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Đối tác'),
              ),
            ],
          ),
          
          // Đường kẻ dọc phân cách
          const VerticalDivider(thickness: 1, width: 1),

          // 2. Màn hình nội dung bên phải
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
      return const MarketExportScreen(); // <--- Đã gắn màn hình Xuất Chợ vào đây
    case 2:
      return const Center(child: Text("Màn hình NHẬP KHO (Sẽ làm tiếp theo)"));
    case 3:
      return const Center(child: Text("Quản lý Đối tác & Công nợ"));
    default:
      return const SizedBox();
  }
}
} 