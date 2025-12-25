import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';

// Import các màn hình con
import '../market_export/market_export_screen.dart';
import '../market_export/scale_test_screen.dart';
import '../market_import/market_import_screen.dart';
import '../import_barn/import_barn_screen.dart';
import '../export_barn/export_barn_screen.dart';
import '../history/invoice_history_screen.dart';
import '../partners/partners_screen.dart';
import '../pig_types/pig_types_screen.dart';
import '../market_report/market_report_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/overview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Danh sách các menu items
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Tổng quan'),
    _NavItem(Icons.input_outlined, Icons.input, 'Nhập Kho'),
    _NavItem(Icons.outbox_outlined, Icons.outbox, 'Xuất Kho'),
    _NavItem(Icons.storefront_outlined, Icons.storefront, 'Xuất Chợ'),
    _NavItem(Icons.shopping_basket_outlined, Icons.shopping_basket, 'Nhập Chợ'),
    _NavItem(Icons.people_outline, Icons.people, 'Đối tác'),
    _NavItem(Icons.pets_outlined, Icons.pets, 'Loại heo'),
    _NavItem(Icons.history_outlined, Icons.history, 'Lịch sử'),
    _NavItem(Icons.assessment_outlined, Icons.assessment, 'Báo cáo chợ'),
    _NavItem(Icons.usb_outlined, Icons.usb, 'Test Cân'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Cài đặt'),
  ];

  // Bottom nav chỉ hiện 4 items chính, còn lại trong drawer
  static const List<int> _bottomNavIndexes = [0, 3, 4, 10]; // Tổng quan, Xuất Chợ, Nhập Chợ, Cài đặt

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    
    // Mobile: Bottom Navigation + Drawer
    if (Responsive.isMobile) {
      return _buildMobileLayout();
    }
    
    // Tablet: Drawer + Content
    if (Responsive.isTablet) {
      return _buildTabletLayout();
    }
    
    // Laptop/Desktop: NavigationRail + Content
    return _buildDesktopLayout();
  }

  /// Mobile layout với Bottom Navigation và Drawer
  Widget _buildMobileLayout() {
    // Tìm index trong bottom nav items tương ứng với _selectedIndex
    int bottomNavIndex = _bottomNavIndexes.indexOf(_selectedIndex);
    if (bottomNavIndex == -1) bottomNavIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = _bottomNavIndexes[index];
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
        destinations: _bottomNavIndexes.map((navIndex) {
          final item = _navItems[navIndex];
          return NavigationDestination(
            icon: Icon(item.icon, size: 22),
            selectedIcon: Icon(item.selectedIcon, size: 22),
            label: _getShortLabel(item.label),
          );
        }).toList(),
      ),
    );
  }

  /// Tablet layout với Drawer
  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(_selectedIndex),
    );
  }

  /// Desktop/Laptop layout với NavigationRail
  Widget _buildDesktopLayout() {
    final bool extended = Responsive.screenWidth >= 1400;
    
    return Scaffold(
      body: Row(
        children: [
          // NavigationRail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: extended,
            minExtendedWidth: 180,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            groupAlignment: -0.9,
            leading: extended 
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.scale, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Cân Heo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Icon(Icons.scale, color: Colors.green.shade700, size: 28),
                ),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          
          const VerticalDivider(thickness: 1, width: 1),

          // Content
          Expanded(
            child: _buildBody(_selectedIndex),
          ),
        ],
      ),
    );
  }

  /// Drawer cho mobile và tablet
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.scale, size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Cân Heo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Menu items
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;
                  
                  return ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? Colors.green.shade700 : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.green.shade700 : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.green.shade50,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.pop(context); // Đóng drawer
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rút gọn label cho bottom nav
  String _getShortLabel(String label) {
    switch (label) {
      case 'Tổng quan':
        return 'Tổng quan';
      case 'Xuất Chợ':
        return 'Xuất';
      case 'Nhập Chợ':
        return 'Nhập';
      case 'Cài đặt':
        return 'Cài đặt';
      default:
        return label;
    }
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const OverviewScreen();
      case 1:
        return const ImportBarnScreen();
      case 2:
        return const ExportBarnScreen();
      case 3:
        return const MarketExportScreen();
      case 4:
        return const MarketImportScreen();
      case 5:
        return const PartnersScreen();
      case 6:
        return const PigTypesScreen();
      case 7:
        return const InvoiceHistoryScreen(invoiceType: 2);
      case 8:
        return const MarketReportScreen();
      case 9:
        return const ScaleTestScreen();
      case 10:
        return const SettingsScreen();
      default:
        return const SizedBox();
    }
  }
}

/// Helper class for navigation items
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.icon, this.selectedIcon, this.label);
}