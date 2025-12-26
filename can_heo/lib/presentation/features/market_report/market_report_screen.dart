import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../injection_container.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/transaction.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Báo Cáo Chợ'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        actions: [
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
                  if (state.startDate == null || state.endDate == null)
                    return true;
                  return !inv.createdDate.isBefore(state.startDate!) &&
                      inv.createdDate.isBefore(state.endDate!);
                }).toList();

                final filteredExports = state.marketExports.where((inv) {
                  if (state.startDate == null || state.endDate == null)
                    return true;
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

  /// Bảng báo cáo chi tiết theo đơn giá (giống bản nháp)
  Widget _buildDetailedReportTable({
    required String title,
    required List<InvoiceEntity> invoices,
    required Color color,
    required CostSummary? costSummary,
    required bool showCosts,
  }) {
    // Nhóm theo đơn giá
    final priceGroups = <double, _PriceGroup>{};

    for (final inv in invoices) {
      final price = inv.pricePerKg;
      if (!priceGroups.containsKey(price)) {
        priceGroups[price] = _PriceGroup(price);
      }
      priceGroups[price]!.quantity += inv.totalQuantity;
      priceGroups[price]!.weight += inv.totalWeight;
      priceGroups[price]!.amount += inv.finalAmount;
      if (inv.note != null && inv.note!.isNotEmpty) {
        priceGroups[price]!.note = inv.note;
      }
    }

    // Sắp xếp theo đơn giá giảm dần
    final sortedGroups = priceGroups.values.toList()
      ..sort((a, b) => b.pricePerKg.compareTo(a.pricePerKg));

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
                    _buildTableCell('', flex: 2, align: TextAlign.center),
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
    );
  }

  // ==================== TAB 3: NHẬP HÀNG ====================
  Widget _buildPurchaseTab(List<InvoiceEntity> imports) {
    return _buildDetailedInvoiceTab(
      imports,
      'Nhập hàng (Nhập chợ)',
      Colors.blue,
      Icons.inventory,
    );
  }

  Widget _buildDetailedInvoiceTab(
    List<InvoiceEntity> invoices,
    String title,
    Color color,
    IconData icon,
  ) {
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
        // Summary bar
        Container(
          padding: const EdgeInsets.all(12),
          color: color.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildDebtCard(
                  'Nợ phát sinh',
                  debt.totalDebt,
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Đã thanh toán',
                  debt.totalPaid,
                  Icons.payment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Đã trả nợ',
                  debt.totalDebtPaid,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebtCard(
                  'Còn nợ',
                  debt.remaining,
                  Icons.account_balance_wallet,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment transactions list
          _buildPaymentTransactionsList(state.transactions),
        ],
      ),
    );
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
    // Filter payment transactions (type = 1 = Chi)
    final paymentTransactions = transactions.where((t) {
      final note = t.note?.toLowerCase() ?? '';
      return t.type == 1 &&
          (note.contains('thanh toán') || note.contains('trả nợ'));
    }).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: const Text(
              'Lịch sử thanh toán / trả nợ',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            ...paymentTransactions.map((t) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        t.note?.toLowerCase().contains('trả nợ') == true
                            ? Colors.green
                            : Colors.blue,
                    child: Icon(
                      t.note?.toLowerCase().contains('trả nợ') == true
                          ? Icons.check_circle
                          : Icons.payment,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(t.partnerName ?? 'N/A'),
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
                      color: t.note?.toLowerCase().contains('trả nợ') == true
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isThreeLine: t.note != null && t.note!.isNotEmpty,
                )),
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

/// Model nhóm theo đơn giá
class _PriceGroup {
  final double pricePerKg;
  int quantity = 0;
  double weight = 0;
  double amount = 0;
  String? note;

  _PriceGroup(this.pricePerKg);

  double get avgWeight => quantity > 0 ? weight / quantity : 0;
}

/// Model chi phí
class _CostItem {
  final String label;
  final double amount;

  _CostItem(this.label, this.amount);
}
