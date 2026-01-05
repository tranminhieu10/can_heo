import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../injection_container.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/services/excel_export_service.dart';
import 'bloc/market_report_bloc.dart';

class MarketReportScreen extends StatelessWidget {
  const MarketReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MarketReportBloc>()
        ..add(const MarketReportSubscriptionRequested()),
      child: const MarketReportView(),
    );
  }
}

class MarketReportView extends StatefulWidget {
  const MarketReportView({super.key});

  @override
  State<MarketReportView> createState() => _MarketReportViewState();
}

class _MarketReportViewState extends State<MarketReportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  final _numberFormat = NumberFormat('#,##0.0', 'vi_VN');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    _endDate =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketReportBloc>().add(
            MarketReportDateRangeChanged(
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _applyDateFilter();
    }
  }

  void _applyDateFilter() {
    context.read<MarketReportBloc>().add(
          MarketReportDateRangeChanged(
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  /// Hiển thị dialog xuất Excel với giao diện chuyên nghiệp
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.file_download,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xuất Báo Cáo Excel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Báo cáo tổng hợp
                    _buildExportSection(
                      title: '📊 Báo cáo tổng hợp',
                      items: [
                        _ExportItem(
                          icon: Icons.dashboard,
                          color: Colors.teal,
                          title: 'Tổng hợp',
                          subtitle: 'Bao gồm bán hàng, nhập hàng, lãi/lỗ',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'overview');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section: Báo cáo chi tiết
                    _buildExportSection(
                      title: '📋 Báo cáo chi tiết',
                      items: [
                        _ExportItem(
                          icon: Icons.sell,
                          color: Colors.green,
                          title: 'Bán hàng',
                          subtitle: 'Chi tiết các phiếu xuất chợ',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'sales');
                          },
                        ),
                        _ExportItem(
                          icon: Icons.inventory,
                          color: Colors.blue,
                          title: 'Nhập hàng',
                          subtitle: 'Chi tiết các phiếu nhập chợ',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'purchase');
                          },
                        ),
                        _ExportItem(
                          icon: Icons.money_off,
                          color: Colors.orange,
                          title: 'Chi phí',
                          subtitle: 'Cước xe, chi phí cân, thải loại',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'cost');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section: Công nợ
                    _buildExportSection(
                      title: '💰 Công nợ',
                      items: [
                        _ExportItem(
                          icon: Icons.account_balance_wallet,
                          color: Colors.red,
                          title: 'Tổng hợp công nợ',
                          subtitle: 'Bao gồm cả NCC và khách hàng',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'debt');
                          },
                        ),
                        _ExportItem(
                          icon: Icons.business,
                          color: Colors.orange,
                          title: 'Công nợ NCC',
                          subtitle: 'Ta nợ nhà cung cấp',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'debt_supplier');
                          },
                        ),
                        _ExportItem(
                          icon: Icons.people,
                          color: Colors.purple,
                          title: 'Công nợ khách hàng',
                          subtitle: 'Khách hàng nợ ta',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'debt_customer');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section: Báo cáo theo đối tác
                    _buildExportSection(
                      title: '👤 Báo cáo theo đối tác',
                      items: [
                        _ExportItem(
                          icon: Icons.person_outline,
                          color: Colors.green.shade700,
                          title: 'Bán hàng theo đối tác',
                          subtitle: 'Chọn khách hàng cụ thể',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'by_partner_sales');
                          },
                        ),
                        _ExportItem(
                          icon: Icons.person_outline,
                          color: Colors.blue.shade700,
                          title: 'Nhập hàng theo đối tác',
                          subtitle: 'Chọn nhà cung cấp cụ thể',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _handleExportExcel(context, 'by_partner_purchase');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection({
    required String title,
    required List<_ExportItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.download_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.grey.shade200, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _selectToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _applyDateFilter();
  }

  void _selectThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _startDate =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _applyDateFilter();
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _applyDateFilter();
  }

  Future<void> _handleExportExcel(BuildContext context, String type) async {
    // Capture before async
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final state = context.read<MarketReportBloc>().state;
    
    // Filter invoices by date
    final filteredImports = state.marketImports.where((inv) {
      if (state.startDate == null || state.endDate == null) return true;
      return !inv.createdDate.isBefore(state.startDate!) &&
          inv.createdDate.isBefore(state.endDate!);
    }).toList();

    final filteredExports = state.marketExports.where((inv) {
      if (state.startDate == null || state.endDate == null) return true;
      return !inv.createdDate.isBefore(state.startDate!) &&
          inv.createdDate.isBefore(state.endDate!);
    }).toList();

    try {
      switch (type) {
        case 'overview':
          await ExcelExportService.exportOverviewReport(
            imports: filteredImports,
            exports: filteredExports,
            otherCost: state.costSummary.otherCost,
            transportFee: state.costSummary.transportFee,
            rejectAmount: state.costSummary.rejectAmount,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case 'sales':
          if (filteredExports.isEmpty) {
            throw Exception('Không có dữ liệu bán hàng để xuất.');
          }
          await ExcelExportService.exportSalesOrPurchaseReport(
            invoices: filteredExports,
            reportType: 'ban_hang',
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case 'purchase':
          if (filteredImports.isEmpty) {
            throw Exception('Không có dữ liệu nhập hàng để xuất.');
          }
          await ExcelExportService.exportSalesOrPurchaseReport(
            invoices: filteredImports,
            reportType: 'nhap_hang',
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case 'cost':
          await ExcelExportService.exportCostReport(
            otherCost: state.costSummary.otherCost,
            transportFee: state.costSummary.transportFee,
            rejectAmount: state.costSummary.rejectAmount,
            otherCostNote: state.costSummary.otherCostNote,
            rejectNote: state.costSummary.rejectNote,
            transactions: state.transactions,
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        case 'debt':
          final debt = state.debtSummary;
          await ExcelExportService.exportDebtReport(
            totalDebt: debt.totalSupplierDebt + debt.totalCustomerDebt,
            totalPaid: debt.totalSupplierPaid + debt.totalCustomerPaid,
            totalDebtPaid: debt.totalSupplierPaid + debt.totalCustomerPaid,
            remaining: debt.supplierRemaining + debt.customerRemaining,
            transactions: state.transactions,
            startDate: _startDate,
            endDate: _endDate,
            totalSupplierDebt: debt.totalSupplierDebt,
            totalSupplierPaid: debt.totalSupplierPaid,
            supplierRemaining: debt.supplierRemaining,
            totalCustomerDebt: debt.totalCustomerDebt,
            totalCustomerPaid: debt.totalCustomerPaid,
            customerRemaining: debt.customerRemaining,
            supplierDebts: debt.supplierDebts.map((d) => DebtInfo(
              partnerName: d.partnerName,
              totalAmount: d.totalAmount,
              totalPaid: d.totalPaid,
              debtAmount: d.debtAmount,
              debtPaid: d.debtPaid,
              remaining: d.remaining,
              invoiceCount: d.invoiceCount,
            )).toList(),
            customerDebts: debt.customerDebts.map((d) => DebtInfo(
              partnerName: d.partnerName,
              totalAmount: d.totalAmount,
              totalPaid: d.totalPaid,
              debtAmount: d.debtAmount,
              debtPaid: d.debtPaid,
              remaining: d.remaining,
              invoiceCount: d.invoiceCount,
            )).toList(),
          );
          break;
        case 'debt_supplier':
          // Chỉ xuất công nợ NCC
          final debt = state.debtSummary;
          await ExcelExportService.exportDebtReport(
            totalDebt: debt.totalSupplierDebt,
            totalPaid: debt.totalSupplierPaid,
            totalDebtPaid: debt.totalSupplierPaid,
            remaining: debt.supplierRemaining,
            transactions: state.transactions.where((t) => 
              t.type == 1 && // Chi
              (t.note?.toLowerCase().contains('thanh toán') == true || 
               t.note?.toLowerCase().contains('trả nợ') == true)
            ).toList(),
            startDate: _startDate,
            endDate: _endDate,
            totalSupplierDebt: debt.totalSupplierDebt,
            totalSupplierPaid: debt.totalSupplierPaid,
            supplierRemaining: debt.supplierRemaining,
            totalCustomerDebt: 0,
            totalCustomerPaid: 0,
            customerRemaining: 0,
            supplierDebts: debt.supplierDebts.map((d) => DebtInfo(
              partnerName: d.partnerName,
              totalAmount: d.totalAmount,
              totalPaid: d.totalPaid,
              debtAmount: d.debtAmount,
              debtPaid: d.debtPaid,
              remaining: d.remaining,
              invoiceCount: d.invoiceCount,
            )).toList(),
            customerDebts: [],
            reportTitle: 'CÔNG NỢ NHÀ CUNG CẤP',
          );
          break;
        case 'debt_customer':
          // Chỉ xuất công nợ khách hàng
          final debtCustomer = state.debtSummary;
          await ExcelExportService.exportDebtReport(
            totalDebt: debtCustomer.totalCustomerDebt,
            totalPaid: debtCustomer.totalCustomerPaid,
            totalDebtPaid: debtCustomer.totalCustomerPaid,
            remaining: debtCustomer.customerRemaining,
            transactions: state.transactions.where((t) => 
              t.type == 0 && // Thu
              (t.note?.toLowerCase().contains('thanh toán') == true || 
               t.note?.toLowerCase().contains('trả nợ') == true)
            ).toList(),
            startDate: _startDate,
            endDate: _endDate,
            totalSupplierDebt: 0,
            totalSupplierPaid: 0,
            supplierRemaining: 0,
            totalCustomerDebt: debtCustomer.totalCustomerDebt,
            totalCustomerPaid: debtCustomer.totalCustomerPaid,
            customerRemaining: debtCustomer.customerRemaining,
            supplierDebts: [],
            customerDebts: debtCustomer.customerDebts.map((d) => DebtInfo(
              partnerName: d.partnerName,
              totalAmount: d.totalAmount,
              totalPaid: d.totalPaid,
              debtAmount: d.debtAmount,
              debtPaid: d.debtPaid,
              remaining: d.remaining,
              invoiceCount: d.invoiceCount,
            )).toList(),
            reportTitle: 'CÔNG NỢ KHÁCH HÀNG',
          );
          break;
        case 'by_partner_sales':
          await _showPartnerSelectionDialog(
            context: context,
            invoices: filteredExports,
            reportType: 'ban_hang',
            title: 'Chọn đối tác (Bán hàng)',
          );
          return; // Don't show success message here, dialog handles it
        case 'by_partner_purchase':
          await _showPartnerSelectionDialog(
            context: context,
            invoices: filteredImports,
            reportType: 'nhap_hang',
            title: 'Chọn đối tác (Nhập hàng)',
          );
          return; // Don't show success message here, dialog handles it
      }
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xuất file Excel thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPartnerSelectionDialog({
    required BuildContext context,
    required List<InvoiceEntity> invoices,
    required String reportType,
    required String title,
  }) async {
    // Capture before async
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (invoices.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Không có dữ liệu trong khoảng thời gian này'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy danh sách đối tác duy nhất
    final partners = <String, int>{}; // partnerId -> count
    final partnerNames = <String, String>{}; // partnerId -> partnerName
    
    for (final inv in invoices) {
      final partnerId = inv.partnerId ?? 'unknown';
      final partnerName = inv.partnerName ?? 'Không xác định';
      partners[partnerId] = (partners[partnerId] ?? 0) + 1;
      partnerNames[partnerId] = partnerName;
    }

    // Sắp xếp theo tên
    final sortedPartnerIds = partners.keys.toList()
      ..sort((a, b) => (partnerNames[a] ?? '').compareTo(partnerNames[b] ?? ''));

    final selectedPartnerId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Từ ${_dateFormat.format(_startDate)} đến ${_dateFormat.format(_endDate)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text('Chọn đối tác để xuất báo cáo:'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedPartnerIds.length,
                  itemBuilder: (context, index) {
                    final partnerId = sortedPartnerIds[index];
                    final partnerName = partnerNames[partnerId] ?? 'N/A';
                    final count = partners[partnerId] ?? 0;
                    
                    // Tính tổng tiền của đối tác
                    final partnerInvoices = invoices.where((inv) => 
                        (inv.partnerId ?? 'unknown') == partnerId).toList();
                    final totalAmount = partnerInvoices.fold<double>(
                        0, (sum, inv) => sum + inv.finalAmount);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: reportType == 'ban_hang' 
                            ? Colors.green.shade100 
                            : Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          color: reportType == 'ban_hang' 
                              ? Colors.green 
                              : Colors.blue,
                        ),
                      ),
                      title: Text(
                        partnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$count phiếu - ${_currencyFormat.format(totalAmount)}đ'),
                      onTap: () => Navigator.of(ctx).pop(partnerId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('HỦY'),
          ),
        ],
      ),
    );

    if (selectedPartnerId == null) return;

    // Lọc phiếu theo đối tác đã chọn
    final partnerInvoices = invoices.where((inv) => 
        (inv.partnerId ?? 'unknown') == selectedPartnerId).toList();
    
    final partnerName = partnerNames[selectedPartnerId] ?? 'N/A';

    try {
      await ExcelExportService.exportByPartnerReport(
        invoices: partnerInvoices,
        partnerName: partnerName,
        reportType: reportType,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('✅ Đã xuất báo cáo "$partnerName" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Báo Cáo Chợ'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Nút xuất Excel
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Xuất Excel',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              context.read<MarketReportBloc>().add(
                    const MarketReportRefreshRequested(),
                  );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng hợp'),
            Tab(icon: Icon(Icons.sell), text: 'Bán hàng'),
            Tab(icon: Icon(Icons.inventory), text: 'Nhập hàng'),
            Tab(icon: Icon(Icons.money_off), text: 'Chi phí'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Công nợ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Filter
          _buildDateFilterBar(),
          // Tab Content
          Expanded(
            child: BlocBuilder<MarketReportBloc, MarketReportState>(
              builder: (context, state) {
                if (state.status == MarketReportStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == MarketReportStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                            'Đã có lỗi xảy ra: ${state.errorMessage ?? "Unknown"}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _applyDateFilter,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter invoices by date
                final filteredImports = state.marketImports.where((inv) {
                  if (state.startDate == null || state.endDate == null) {
                    return true;
                  }
                  return !inv.createdDate.isBefore(state.startDate!) &&
                      inv.createdDate.isBefore(state.endDate!);
                }).toList();

                final filteredExports = state.marketExports.where((inv) {
                  if (state.startDate == null || state.endDate == null) {
                    return true;
                  }
                  return !inv.createdDate.isBefore(state.startDate!) &&
                      inv.createdDate.isBefore(state.endDate!);
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(state, filteredImports, filteredExports),
                    _buildSalesTab(filteredExports),
                    _buildPurchaseTab(filteredImports),
                    _buildCostTab(state),
                    _buildDebtTab(state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // Quick filters
          _buildQuickFilterChip('Hôm nay', _selectToday),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Tuần này', _selectThisWeek),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Tháng này', _selectThisMonth),
          const Spacer(),
          // Date range display
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, color: Colors.teal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.teal.shade300),
    );
  }

  // ==================== TAB 1: TỔNG HỢP ====================
  Widget _buildOverviewTab(
    MarketReportState state,
    List<InvoiceEntity> imports,
    List<InvoiceEntity> exports,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bảng chi tiết BÁN HÀNG (Xuất chợ)
          _buildDetailedReportTable(
            title: '📤 BÁN HÀNG (Xuất chợ)',
            invoices: exports,
            color: Colors.green,
            costSummary: state.costSummary,
            showCosts: true,
          ),
          const SizedBox(height: 24),

          // Bảng chi tiết NHẬP HÀNG (Nhập chợ)
          _buildDetailedReportTable(
            title: '📥 NHẬP HÀNG (Nhập chợ)',
            invoices: imports,
            color: Colors.blue,
            costSummary: null,
            showCosts: false,
          ),
          const SizedBox(height: 24),

          // Tổng kết lãi/lỗ
          _buildProfitSummaryCard(imports, exports, state.costSummary),
        ],
      ),
    );
  }

  /// Bảng báo cáo chi tiết theo ngày + đơn giá (giống bản nháp)
  Widget _buildDetailedReportTable({
    required String title,
    required List<InvoiceEntity> invoices,
    required Color color,
    required CostSummary? costSummary,
    required bool showCosts,
  }) {
    // Nhóm theo ngày + đơn giá
    final priceGroups = <String, _PriceGroup>{};

    for (final inv in invoices) {
      final date = DateTime(inv.createdDate.year, inv.createdDate.month, inv.createdDate.day);
      final price = inv.pricePerKg;
      final key = '${date.year}-${date.month}-${date.day}_$price';
      
      if (!priceGroups.containsKey(key)) {
        priceGroups[key] = _PriceGroup(date, price);
      }
      priceGroups[key]!.quantity += inv.totalQuantity;
      priceGroups[key]!.weight += inv.totalWeight;
      priceGroups[key]!.amount += inv.finalAmount;
      if (inv.note != null && inv.note!.isNotEmpty) {
        priceGroups[key]!.note = inv.note;
      }
    }

    // Sắp xếp theo ngày giảm dần, sau đó theo đơn giá giảm dần
    final sortedGroups = priceGroups.values.toList()
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.pricePerKg.compareTo(a.pricePerKg);
      });

    // Tính tổng
    final totalQuantity =
        sortedGroups.fold<int>(0, (sum, g) => sum + g.quantity);
    final totalWeight =
        sortedGroups.fold<double>(0, (sum, g) => sum + g.weight);
    final totalAmount =
        sortedGroups.fold<double>(0, (sum, g) => sum + g.amount);
    final avgWeight = totalQuantity > 0 ? totalWeight / totalQuantity : 0;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0;

    // Chi phí
    final transportFee = costSummary?.transportFee ?? 0;
    final otherCost = costSummary?.otherCost ?? 0;
    final rejectAmount = costSummary?.rejectAmount ?? 0;
    final totalCost = transportFee + otherCost + rejectAmount;
    final grandTotal = totalAmount - totalCost;

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Table Header
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                _buildTableHeaderCell('Ngày\ntháng', flex: 2),
                _buildTableHeaderCell('Số lượng\ncon', flex: 2),
                _buildTableHeaderCell('Số lượng\nkg', flex: 3),
                _buildTableHeaderCell('Bình Quân\nkg', flex: 2),
                _buildTableHeaderCell('Đơn giá\nVND', flex: 3),
                _buildTableHeaderCell('Ghi chú', flex: 5),
                _buildTableHeaderCell('Thành tiền', flex: 4),
              ],
            ),
          ),

          // Data Rows
          ...sortedGroups.map((group) => Container(
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  children: [
                    _buildTableCell(_dateFormat.format(group.date), flex: 2, align: TextAlign.center),
                    _buildTableCell('${group.quantity}',
                        flex: 2, align: TextAlign.center),
                    _buildTableCell(_numberFormat.format(group.weight),
                        flex: 3, align: TextAlign.center),
                    _buildTableCell(_numberFormat.format(group.avgWeight),
                        flex: 2, align: TextAlign.center),
                    _buildTableCell(_currencyFormat.format(group.pricePerKg),
                        flex: 3, align: TextAlign.center),
                    _buildTableCell(group.note ?? '', flex: 5, align: TextAlign.center),
                    _buildTableCell(_currencyFormat.format(group.amount),
                        flex: 4, align: TextAlign.center, bold: true),
                  ],
                ),
              )),

          // Subtotal Row
          Container(
            color: color.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _buildTableCell('', flex: 2, align: TextAlign.center),
                _buildTableCell('$totalQuantity',
                    flex: 2, align: TextAlign.center, bold: true),
                _buildTableCell(_numberFormat.format(totalWeight),
                    flex: 3, align: TextAlign.center, bold: true),
                _buildTableCell(_numberFormat.format(avgWeight),
                    flex: 2, align: TextAlign.center, bold: true),
                _buildTableCell(_currencyFormat.format(avgPrice),
                    flex: 3, align: TextAlign.center, bold: true),
                _buildTableCell('', flex: 5, align: TextAlign.center),
                _buildTableCell(_currencyFormat.format(totalAmount),
                    flex: 4, align: TextAlign.center, bold: true, color: color),
              ],
            ),
          ),

          // Chi phí (nếu có)
          if (showCosts && totalCost > 0) ...[
            const Divider(height: 1),
            if (transportFee > 0) _buildCostRow('Cước xe', transportFee),
            if (otherCost > 0) _buildCostRow('Chi phí cân', otherCost),
            if (rejectAmount > 0) _buildCostRow('Thải loại', rejectAmount),
          ],

          // Grand Total (nếu có chi phí)
          if (showCosts) ...[
            const Divider(height: 1, thickness: 2),
            Container(
              color: grandTotal >= 0
                  ? color.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  _buildTableCell('', flex: 2, align: TextAlign.center),
                  _buildTableCell('$totalQuantity',
                      flex: 2, align: TextAlign.center, bold: true),
                  _buildTableCell(_numberFormat.format(totalWeight),
                      flex: 3, align: TextAlign.center, bold: true),
                  _buildTableCell(_numberFormat.format(avgWeight),
                      flex: 2, align: TextAlign.center, bold: true),
                  _buildTableCell(_currencyFormat.format(avgPrice),
                      flex: 3, align: TextAlign.center, bold: true),
                  _buildTableCell('', flex: 5, align: TextAlign.center),
                  _buildTableCell(
                    grandTotal >= 0
                        ? _currencyFormat.format(grandTotal)
                        : '-${_currencyFormat.format(grandTotal.abs())}',
                    flex: 4,
                    align: TextAlign.center,
                    bold: true,
                    color: grandTotal >= 0 ? color : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    int flex = 1,
    TextAlign align = TextAlign.left,
    bool bold = false,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          // Căn theo các cột trước đó
          Expanded(flex: 2, child: Container()),
          Expanded(flex: 2, child: Container()),
          Expanded(flex: 3, child: Container()),
          Expanded(flex: 2, child: Container()),
          Expanded(flex: 3, child: Container()),
          Expanded(
            flex: 5,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _currencyFormat.format(amount),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSummaryCard(
    List<InvoiceEntity> imports,
    List<InvoiceEntity> exports,
    CostSummary costSummary,
  ) {
    final importAmount =
        imports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final exportAmount =
        exports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final totalCost = costSummary.total;
    final profit = exportAmount - importAmount - totalCost;

    final importWeight =
        imports.fold<double>(0, (sum, inv) => sum + inv.totalWeight);
    final exportWeight =
        exports.fold<double>(0, (sum, inv) => sum + inv.totalWeight);
    final remainingWeight = importWeight - exportWeight;

    return Card(
      elevation: 4,
      color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '📊 TỔNG KẾT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryColumn('Tiền nhập', importAmount, Colors.blue),
                _buildSummaryColumn('Tiền bán', exportAmount, Colors.green),
                _buildSummaryColumn('Chi phí', totalCost, Colors.orange),
                _buildSummaryColumn(
                  profit >= 0 ? 'LÃI' : 'LỖ',
                  profit.abs(),
                  profit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tồn kho: ${_numberFormat.format(remainingWeight)} kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: remainingWeight > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '${_currencyFormat.format(value)}đ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, Color color, List<_SummaryItem> items) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(top: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label,
                          style: const TextStyle(color: Colors.grey)),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.valueColor ?? Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTable(
      String title, List<InvoiceEntity> invoices, Color color) {
    // Group by partner
    final grouped = <String, _PartnerSummary>{};
    for (final inv in invoices) {
      final partnerId = inv.partnerId ?? 'unknown';
      final partnerName = inv.partnerName ?? 'Không xác định';

      if (!grouped.containsKey(partnerId)) {
        grouped[partnerId] = _PartnerSummary(partnerName);
      }
      grouped[partnerId]!.count++;
      grouped[partnerId]!.weight += inv.totalWeight;
      grouped[partnerId]!.amount += inv.finalAmount;
    }

    final sortedPartners = grouped.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          DataTable(
            columnSpacing: 20,
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 36,
            columns: const [
              DataColumn(
                  label: Text('Đối tác',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label:
                      Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true),
              DataColumn(
                  label: Text('KL (kg)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true),
              DataColumn(
                  label: Text('Thành tiền',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true),
            ],
            rows: sortedPartners
                .map((p) => DataRow(
                      cells: [
                        DataCell(Text(p.name, overflow: TextOverflow.ellipsis)),
                        DataCell(Text('${p.count}')),
                        DataCell(Text(_numberFormat.format(p.weight))),
                        DataCell(Text(_currencyFormat.format(p.amount))),
                      ],
                    ))
                .toList(),
          ),
          if (sortedPartners.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TỔNG: ${sortedPartners.fold<int>(0, (sum, p) => sum + p.count)} phiếu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_currencyFormat.format(sortedPartners.fold<double>(0, (sum, p) => sum + p.amount))}đ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== TAB 2: BÁN HÀNG ====================
  Widget _buildSalesTab(List<InvoiceEntity> exports) {
    return _buildDetailedInvoiceTab(
      exports,
      'Bán hàng (Xuất chợ)',
      Colors.green,
      Icons.sell,
      exportType: 'ban_hang',
    );
  }

  // ==================== TAB 3: NHẬP HÀNG ====================
  Widget _buildPurchaseTab(List<InvoiceEntity> imports) {
    return _buildDetailedInvoiceTab(
      imports,
      'Nhập hàng (Nhập chợ)',
      Colors.blue,
      Icons.inventory,
      exportType: 'nhap_hang',
    );
  }

  Widget _buildDetailedInvoiceTab(
    List<InvoiceEntity> invoices,
    String title,
    Color color,
    IconData icon, {
    String? exportType,
  }) {
    // Sort by date desc
    final sortedInvoices = List<InvoiceEntity>.from(invoices)
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

    // Calculate totals
    final totalQuantity =
        invoices.fold<int>(0, (sum, inv) => sum + inv.totalQuantity);
    final totalWeight =
        invoices.fold<double>(0, (sum, inv) => sum + inv.totalWeight);
    final totalAmount =
        invoices.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final avgWeight = totalQuantity > 0 ? totalWeight / totalQuantity : 0;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0;

    return Column(
      children: [
        // Summary bar with export button
        Container(
          padding: const EdgeInsets.all(12),
          color: color.withValues(alpha: 0.1),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                        'Số phiếu', '${invoices.length}', Icons.receipt, color),
                    _buildStatChip('Tổng con', '$totalQuantity', Icons.pets, color),
                    _buildStatChip(
                        'Tổng KL',
                        '${_numberFormat.format(totalWeight)} kg',
                        Icons.scale,
                        color),
                    _buildStatChip('BQ/con', '${_numberFormat.format(avgWeight)} kg',
                        Icons.balance, color),
                    _buildStatChip('Giá BQ', '${_currencyFormat.format(avgPrice)}',
                        Icons.attach_money, color),
                    _buildStatChip(
                        'Tổng tiền',
                        '${_currencyFormat.format(totalAmount)}đ',
                        Icons.payments,
                        color),
                  ],
                ),
              ),
              if (exportType != null && invoices.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.file_download, color: color),
                  tooltip: 'Xuất Excel',
                  onPressed: () async {
                    try {
                      await ExcelExportService.exportSalesOrPurchaseReport(
                        invoices: invoices,
                        reportType: exportType,
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã xuất file Excel thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
        // Invoice table
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Không có phiếu $title trong khoảng thời gian này',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Card(
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          color: color.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              _buildTableHeaderCell('Ngày', flex: 2),
                              _buildTableHeaderCell('Đối tác', flex: 3),
                              _buildTableHeaderCell('SL con', flex: 1),
                              _buildTableHeaderCell('KL (kg)', flex: 2),
                              _buildTableHeaderCell('BQ (kg)', flex: 2),
                              _buildTableHeaderCell('Đơn giá', flex: 2),
                              _buildTableHeaderCell('Thành tiền', flex: 3),
                              _buildTableHeaderCell('Ghi chú', flex: 2),
                            ],
                          ),
                        ),
                        // Data rows
                        ...sortedInvoices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final inv = entry.value;
                          final avgW = inv.totalQuantity > 0
                              ? inv.totalWeight / inv.totalQuantity
                              : 0;

                          return Container(
                            color: index.isEven
                                ? Colors.white
                                : Colors.grey.shade50,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: Row(
                              children: [
                                _buildTableCell(
                                    _dateFormat.format(inv.createdDate),
                                    flex: 2,
                                    align: TextAlign.center),
                                _buildTableCell(inv.partnerName ?? 'N/A',
                                    flex: 3, align: TextAlign.center),
                                _buildTableCell('${inv.totalQuantity}',
                                    flex: 1, align: TextAlign.center),
                                _buildTableCell(
                                    _numberFormat.format(inv.totalWeight),
                                    flex: 2,
                                    align: TextAlign.center),
                                _buildTableCell(_numberFormat.format(avgW),
                                    flex: 2, align: TextAlign.center),
                                _buildTableCell(
                                    _currencyFormat.format(inv.pricePerKg),
                                    flex: 2,
                                    align: TextAlign.center),
                                _buildTableCell(
                                    _currencyFormat.format(inv.finalAmount),
                                    flex: 3,
                                    align: TextAlign.center,
                                    bold: true,
                                    color: color),
                                _buildTableCell(inv.note ?? '', flex: 2, align: TextAlign.center),
                              ],
                            ),
                          );
                        }),
                        // Total row
                        Container(
                          color: color.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              _buildTableCell('TỔNG',
                                  flex: 2, bold: true, align: TextAlign.center),
                              _buildTableCell('${invoices.length} phiếu',
                                  flex: 3, bold: true, align: TextAlign.center),
                              _buildTableCell('$totalQuantity',
                                  flex: 1, align: TextAlign.center, bold: true),
                              _buildTableCell(_numberFormat.format(totalWeight),
                                  flex: 2, align: TextAlign.center, bold: true),
                              _buildTableCell(_numberFormat.format(avgWeight),
                                  flex: 2, align: TextAlign.center, bold: true),
                              _buildTableCell(_currencyFormat.format(avgPrice),
                                  flex: 2, align: TextAlign.center, bold: true),
                              _buildTableCell(
                                  _currencyFormat.format(totalAmount),
                                  flex: 3,
                                  align: TextAlign.center,
                                  bold: true,
                                  color: color),
                              _buildTableCell('', flex: 2, align: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(InvoiceEntity inv, Color color) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.receipt, color: color),
        ),
        title: Row(
          children: [
            Text(
              inv.partnerName ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_currencyFormat.format(inv.finalAmount)}đ',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
                '${_dateFormat.format(inv.createdDate)} ${timeFormat.format(inv.createdDate)}'),
            const SizedBox(width: 16),
            Text('${_numberFormat.format(inv.totalWeight)} kg'),
            const SizedBox(width: 16),
            Text('${inv.totalQuantity} con'),
            if (inv.note != null && inv.note!.isNotEmpty) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  inv.note!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
        dense: true,
      ),
    );
  }

  // ==================== TAB 4: CHI PHÍ ====================
  Widget _buildCostTab(MarketReportState state) {
    final cost = state.costSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Export button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ExcelExportService.exportCostReport(
                      otherCost: cost.otherCost,
                      transportFee: cost.transportFee,
                      rejectAmount: cost.rejectAmount,
                      otherCostNote: cost.otherCostNote,
                      rejectNote: cost.rejectNote,
                      transactions: state.transactions,
                      startDate: _startDate,
                      endDate: _endDate,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã xuất file Excel thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('Xuất Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildCostCard(
                  'Chi phí khác',
                  cost.otherCost,
                  Icons.more_horiz,
                  Colors.purple,
                  cost.otherCostNote,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCostCard(
                  'Cước xe',
                  cost.transportFee,
                  Icons.local_shipping,
                  Colors.blue,
                  null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCostCard(
                  'Thải loại',
                  cost.rejectAmount,
                  Icons.delete_outline,
                  Colors.red,
                  cost.rejectNote,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total cost
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 TỔNG CHI PHÍ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currencyFormat.format(cost.total)}đ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cost transactions list
          _buildCostTransactionsList(state.transactions),
        ],
      ),
    );
  }

  Widget _buildCostCard(
    String title,
    double amount,
    IconData icon,
    Color color,
    String? note,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_currencyFormat.format(amount)}đ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostTransactionsList(List<TransactionEntity> transactions) {
    // Filter cost-related transactions (type = 1 = Chi)
    final costTransactions = transactions.where((t) {
      final note = t.note?.toLowerCase() ?? '';
      return t.type == 1 &&
          (note.contains('cước') ||
              note.contains('xe') ||
              note.contains('thải') ||
              note.contains('loại') ||
              note.contains('chi phí') ||
              note.contains('khác'));
    }).toList();

    if (costTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Không có giao dịch chi phí trong khoảng thời gian này',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: const Text(
              'Chi tiết giao dịch chi phí',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...costTransactions.map((t) => ListTile(
                leading: _getCostIcon(t.note),
                title: Text(t.note ?? 'Chi phí'),
                subtitle: Text(
                  '${_dateFormat.format(t.date)} - ${t.partnerName ?? 'N/A'}',
                ),
                trailing: Text(
                  '-${_currencyFormat.format(t.amount)}đ',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _getCostIcon(String? note) {
    final lowerNote = note?.toLowerCase() ?? '';
    if (lowerNote.contains('cước') || lowerNote.contains('xe')) {
      return const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.local_shipping, color: Colors.white, size: 20),
      );
    } else if (lowerNote.contains('thải') || lowerNote.contains('loại')) {
      return const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.delete_outline, color: Colors.white, size: 20),
      );
    }
    return const CircleAvatar(
      backgroundColor: Colors.purple,
      child: Icon(Icons.more_horiz, color: Colors.white, size: 20),
    );
  }

  // ==================== TAB 5: CÔNG NỢ ====================
  Widget _buildDebtTab(MarketReportState state) {
    final debt = state.debtSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Export button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ExcelExportService.exportDebtReport(
                      totalDebt: debt.totalSupplierDebt + debt.totalCustomerDebt,
                      totalPaid: debt.totalSupplierPaid + debt.totalCustomerPaid,
                      totalDebtPaid: debt.totalSupplierPaid + debt.totalCustomerPaid,
                      remaining: debt.supplierRemaining + debt.customerRemaining,
                      transactions: state.transactions,
                      startDate: _startDate,
                      endDate: _endDate,
                      // New params for NCC and Customer separation
                      totalSupplierDebt: debt.totalSupplierDebt,
                      totalSupplierPaid: debt.totalSupplierPaid,
                      supplierRemaining: debt.supplierRemaining,
                      totalCustomerDebt: debt.totalCustomerDebt,
                      totalCustomerPaid: debt.totalCustomerPaid,
                      customerRemaining: debt.customerRemaining,
                      supplierDebts: debt.supplierDebts.map((d) => DebtInfo(
                        partnerName: d.partnerName,
                        totalAmount: d.totalAmount,
                        totalPaid: d.totalPaid,
                        debtAmount: d.debtAmount,
                        debtPaid: d.debtPaid,
                        remaining: d.remaining,
                        invoiceCount: d.invoiceCount,
                      )).toList(),
                      customerDebts: debt.customerDebts.map((d) => DebtInfo(
                        partnerName: d.partnerName,
                        totalAmount: d.totalAmount,
                        totalPaid: d.totalPaid,
                        debtAmount: d.debtAmount,
                        debtPaid: d.debtPaid,
                        remaining: d.remaining,
                        invoiceCount: d.invoiceCount,
                      )).toList(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Đã xuất file Excel thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('Xuất Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // ========== CÔNG NỢ NCC (Ta nợ NCC) ==========
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'CÔNG NỢ NHÀ CUNG CẤP (Ta nợ NCC)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDebtCard(
                  'Nợ NCC phát sinh',
                  debt.totalSupplierDebt,
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Đã trả NCC',
                  debt.totalSupplierPaid,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Còn nợ NCC',
                  debt.supplierRemaining,
                  Icons.account_balance_wallet,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Danh sách NCC còn nợ
          _buildSupplierDebtList(debt.supplierDebts),
          
          const SizedBox(height: 32),
          
          // ========== CÔNG NỢ KHÁCH HÀNG (Khách nợ ta) ==========
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'CÔNG NỢ KHÁCH HÀNG (Khách nợ ta)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDebtCard(
                  'Khách nợ phát sinh',
                  debt.totalCustomerDebt,
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Khách đã trả',
                  debt.totalCustomerPaid,
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Khách còn nợ',
                  debt.customerRemaining,
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Danh sách khách hàng còn nợ
          _buildCustomerDebtList(debt.customerDebts),

          const SizedBox(height: 24),

          // Payment transactions list
          _buildPaymentTransactionsList(state.transactions),
        ],
      ),
    );
  }

  Widget _buildSupplierDebtList(List<CustomerDebt> supplierDebts) {
    // Lọc chỉ những NCC còn nợ
    final debtors = supplierDebts.where((c) => c.remaining > 0).toList();
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Danh sách NCC còn nợ (${debtors.length} NCC)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (debtors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Không nợ NCC nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debtors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final supplier = debtors[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade600,
                    child: Text(
                      supplier.partnerName.isNotEmpty 
                          ? supplier.partnerName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    supplier.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Ta còn nợ: ${_currencyFormat.format(supplier.remaining)}đ',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${supplier.invoiceCount} phiếu',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (supplier.lastTransaction != null)
                        Text(
                          _dateFormat.format(supplier.lastTransaction!),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          _buildDebtDetailRow('Tổng mua hàng', supplier.totalAmount, Colors.blue),
                          _buildDebtDetailRow('Đã thanh toán (lúc mua)', supplier.totalPaid, Colors.green),
                          _buildDebtDetailRow('Nợ phát sinh', supplier.debtAmount, Colors.orange),
                          _buildDebtDetailRow('Đã trả nợ', supplier.debtPaid, Colors.teal),
                          const Divider(),
                          _buildDebtDetailRow('Còn nợ', supplier.remaining, Colors.red, isBold: true),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerDebtList(List<CustomerDebt> customerDebts) {
    // Lọc chỉ những khách còn nợ
    final debtors = customerDebts.where((c) => c.remaining > 0).toList();
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Danh sách khách hàng còn nợ (${debtors.length} khách)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (debtors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Không có khách hàng nào còn nợ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debtors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = debtors[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDebtColor(customer.remaining),
                    child: Text(
                      customer.partnerName.isNotEmpty 
                          ? customer.partnerName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    customer.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Khách còn nợ: ${_currencyFormat.format(customer.remaining)}đ',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${customer.invoiceCount} phiếu',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (customer.lastTransaction != null)
                        Text(
                          _dateFormat.format(customer.lastTransaction!),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade50,
                      child: Column(
                        children: [
                          _buildDebtDetailRow('Tổng bán hàng', customer.totalAmount, Colors.blue),
                          _buildDebtDetailRow('Đã thanh toán (lúc bán)', customer.totalPaid, Colors.green),
                          _buildDebtDetailRow('Nợ phát sinh', customer.debtAmount, Colors.orange),
                          _buildDebtDetailRow('Đã trả nợ', customer.debtPaid, Colors.teal),
                          const Divider(),
                          _buildDebtDetailRow('Còn nợ', customer.remaining, Colors.purple, isBold: true),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDebtDetailRow(String label, double amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${_currencyFormat.format(amount)}đ',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDebtColor(double amount) {
    if (amount > 10000000) return Colors.red.shade700;      // > 10 triệu
    if (amount > 5000000) return Colors.red.shade500;       // > 5 triệu
    if (amount > 1000000) return Colors.orange.shade600;    // > 1 triệu
    return Colors.orange.shade400;
  }

  Widget _buildDebtCard(
      String title, double amount, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_currencyFormat.format(amount)}đ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTransactionsList(List<TransactionEntity> transactions) {
    // Filter payment transactions:
    // - type = 1 (Chi): Ta thanh toán/trả nợ cho NCC
    // - type = 0 (Thu): Khách hàng thanh toán/trả nợ cho ta
    final paymentTransactions = transactions.where((t) {
      final note = t.note?.toLowerCase() ?? '';
      return (note.contains('thanh toán') || note.contains('trả nợ'));
    }).toList();

    // Sort by date descending
    paymentTransactions.sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử thanh toán / trả nợ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${paymentTransactions.length} giao dịch',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (paymentTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Không có giao dịch thanh toán trong khoảng thời gian này',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...paymentTransactions.map((t) {
              // Determine transaction type
              final isFromCustomer = t.type == 0; // Thu = khách trả cho ta
              final isDebtPayment = t.note?.toLowerCase().contains('trả nợ') == true;
              
              // Colors: Thu từ khách = xanh lá/tím, Chi cho NCC = xanh dương/cam
              Color bgColor;
              Color textColor;
              IconData icon;
              String typeLabel;
              
              if (isFromCustomer) {
                // Khách hàng thanh toán/trả nợ cho ta
                bgColor = isDebtPayment ? Colors.purple : Colors.teal;
                textColor = isDebtPayment ? Colors.purple : Colors.teal;
                icon = isDebtPayment ? Icons.arrow_downward : Icons.call_received;
                typeLabel = isDebtPayment ? 'Khách trả nợ' : 'Khách thanh toán';
              } else {
                // Ta thanh toán/trả nợ cho NCC
                bgColor = isDebtPayment ? Colors.green : Colors.blue;
                textColor = isDebtPayment ? Colors.green : Colors.blue;
                icon = isDebtPayment ? Icons.check_circle : Icons.payment;
                typeLabel = isDebtPayment ? 'Trả nợ NCC' : 'Thanh toán NCC';
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: bgColor,
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.partnerName ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dateFormat.format(t.date)),
                    if (t.note != null && t.note!.isNotEmpty)
                      Text(
                        t.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  '${_currencyFormat.format(t.amount)}đ',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isThreeLine: t.note != null && t.note!.isNotEmpty,
              );
            }),
        ],
      ),
    );
  }
}

// Helper classes
class _SummaryItem {
  final String label;
  final String value;
  final Color? valueColor;

  _SummaryItem(this.label, this.value, {this.valueColor});
}

class _PartnerSummary {
  final String name;
  int count = 0;
  double weight = 0;
  double amount = 0;

  _PartnerSummary(this.name);
}

/// Model nhóm theo ngày + đơn giá
class _PriceGroup {
  final DateTime date;
  final double pricePerKg;
  int quantity = 0;
  double weight = 0;
  double amount = 0;
  String? note;

  _PriceGroup(this.date, this.pricePerKg);

  double get avgWeight => quantity > 0 ? weight / quantity : 0;
  
  /// Key duy nhất cho nhóm
  String get key => '${date.year}-${date.month}-${date.day}_$pricePerKg';
}

/// Model chi phí
class _CostItem {
  final String label;
  final double amount;

  _CostItem(this.label, this.amount);
}

/// Model cho item xuất Excel
class _ExportItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ExportItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
