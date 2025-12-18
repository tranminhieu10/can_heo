import 'package:flutter/material.dart';

// Import các màn hình con
import '../market_export/market_export_screen.dart';
import '../market_export/scale_test_screen.dart';
import '../market_import/market_import_screen.dart';
import '../import_barn/import_barn_screen.dart';
import '../export_barn/export_barn_screen.dart';
import '../history/invoice_history_screen.dart';
import '../partners/partners_screen.dart';
import '../pig_types/pig_types_screen.dart';
import '../finance/finance_screen.dart';
import 'widgets/overview_screen.dart';

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
              // Index 0: Tổng quan
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Tổng quan'),
              ),
              // Index 1: Nhập Kho
              NavigationRailDestination(
                icon: Icon(Icons.input_outlined),
                selectedIcon: Icon(Icons.input),
                label: Text('Nhập Kho'),
              ),
              // Index 2: Xuất Kho
              NavigationRailDestination(
                icon: Icon(Icons.outbox_outlined),
                selectedIcon: Icon(Icons.outbox),
                label: Text('Xuất Kho'),
              ),
              // Index 3: Xuất chợ
              NavigationRailDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: Text('Xuất Chợ'),
              ),
              // Index 4: Nhập Chợ
              NavigationRailDestination(
                icon: Icon(Icons.shopping_basket_outlined),
                selectedIcon: Icon(Icons.shopping_basket),
                label: Text('Nhập Chợ'),
              ),
              // Index 5: Tài chính
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Tài chính'),
              ),
              // Index 6: Đối tác
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Đối tác'),
              ),
              // Index 7: Loại heo
              NavigationRailDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: Text('Loại heo'),
              ),
              // Index 8: Lịch sử
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Lịch sử'),
              ),
              // Index 9: Test Cân
              NavigationRailDestination(
                icon: Icon(Icons.usb_outlined),
                selectedIcon: Icon(Icons.usb),
                label: Text('Test Cân'),
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
        return const OverviewScreen(); // Màn hình Tổng quan
      case 1:
        return const ImportBarnScreen(); // Màn hình Nhập Kho
      case 2:
        return const ExportBarnScreen(); // Màn hình Xuất Kho
      case 3:
        return const MarketExportScreen(); // Màn hình Xuất Chợ
      case 4:
        return const MarketImportScreen(); // Màn hình Nhập Chợ
      case 5:
        return const FinanceScreen(); // Màn hình Tài chính
      case 6:
        return const PartnersScreen(); // Màn hình Đối tác
      case 7:
        return const PigTypesScreen(); // Màn hình Loại heo
      case 8:
        return const InvoiceHistoryScreen(invoiceType: 2); // Màn hình Lịch sử
      case 9:
        return const ScaleTestScreen(); // Màn hình Test Cân
      default:
        return const SizedBox();
    }
  }
}