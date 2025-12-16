import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../pig_types/pig_types_screen.dart';

/// Màn hình Nhập Chợ - Nhập hàng thừa từ chợ về kho (hàng trả về)
/// Type = 3 (Nhập chợ / Return to Barn)
class MarketImportScreen extends StatelessWidget {
  const MarketImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PartnerBloc>(
          create: (_) => sl<PartnerBloc>()..add(const LoadPartners(false)),
        ),
      ],
      child: const _MarketImportView(),
    );
  }
}

class _MarketImportView extends StatefulWidget {
  const _MarketImportView();

  @override
  State<_MarketImportView> createState() => _MarketImportViewState();
}

class _MarketImportViewState extends State<_MarketImportView> {
  // Controllers
  final TextEditingController _scaleInputController = TextEditingController();
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _deductionController =
      TextEditingController(text: '0');
  final TextEditingController _discountController =
      TextEditingController(text: '0');

  // Search controllers
  final TextEditingController _searchPartnerController =
      TextEditingController();
  final TextEditingController _searchQuantityController =
      TextEditingController();

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  PartnerEntity? _selectedPartner;
  final _invoiceRepo = sl<IInvoiceRepository>();

  // Track which search columns are visible
  final Set<String> _activeSearchColumns = {};

  // Panel ratio for resizable layout (default 1/3 for form)
  double _panelRatio = 0.33;
  static const double _minPanelRatio = 0.2;
  static const double _maxPanelRatio = 0.5;

  // Payment
  int _selectedPaymentMethod = 0; // 0 = Tiền mặt, 1 = Chuyển khoản, 2 = Nợ

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scaleInputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scaleInputController.dispose();
    _pigTypeController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _deductionController.dispose();
    _discountController.dispose();
    _searchPartnerController.dispose();
    _searchQuantityController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _grossWeight =>
      double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
  double get _deduction => double.tryParse(_deductionController.text) ?? 0;
  double get _netWeight =>
      (_grossWeight - _deduction).clamp(0, double.infinity);
  double get _pricePerKg =>
      double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _subtotal => _netWeight * _pricePerKg;
  double get _autoDiscount => _subtotal - (_subtotal / 1000).floor() * 1000;
  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '')) ??
      _autoDiscount;
  double get _totalAmount => (_subtotal - _discount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () =>
            _saveInvoice(context),
        const SingleActivator(LogicalKeyboardKey.f1): () =>
            _scaleInputFocus.requestFocus(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Phiếu Nhập Chợ'),
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Quản lý Loại heo',
                icon: const Icon(Icons.pets_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PigTypesScreen()),
                ),
              ),
              _buildSaveButton(context),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              Responsive.init(context);

              final debtBarHeight =
                  Responsive.screenType == ScreenType.desktop27 ? 48.0 : 44.0;
              final padding = Responsive.spacing;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // ========== PHẦN 1: Thông tin phiếu - chiếm 1/2 bên trái ==========
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          // Nửa trái: Form thông tin phiếu
                          Expanded(
                            child: _buildInvoiceDetailsSection(context),
                          ),
                          // Nửa phải: để trống
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ========== PHẦN 2: Phiếu đã lưu - 2/3 height ==========
                    Expanded(
                      flex: 2,
                      child: _buildSavedInvoicesGrid(context),
                    ),
                    // ========== PHẦN 3: Công nợ ==========
                    SizedBox(
                      height: debtBarHeight,
                      child: _buildDebtSection(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== SCALE SECTION ====================
  Widget _buildScaleSection(BuildContext context) {
    final fontSize = Responsive.bodyFontSize;

    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '⬇️ NHẬP CHỢ - Hàng trả về từ chợ',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scale display - Direct input
            GestureDetector(
              onTap: () => _scaleInputFocus.requestFocus(),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade400, width: 2),
                ),
                child: Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _scaleInputController,
                      focusNode: _scaleInputFocus,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.screenType == ScreenType.desktop27
                            ? 52
                            : Responsive.screenType == ScreenType.desktop24
                                ? 46
                                : 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          fontSize: Responsive.screenType ==
                                  ScreenType.desktop27
                              ? 52
                              : Responsive.screenType == ScreenType.desktop24
                                  ? 46
                                  : 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.withValues(alpha: 0.3),
                          fontFamily: 'monospace',
                        ),
                        suffixText: ' kg',
                        suffixStyle: TextStyle(
                          fontSize: Responsive.screenType ==
                                  ScreenType.desktop27
                              ? 28
                              : Responsive.screenType == ScreenType.desktop24
                                  ? 24
                                  : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade300,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _scaleInputController.clear();
                      setState(() {});
                      _scaleInputFocus.requestFocus();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveInvoice(context),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Lưu phiếu (F4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Summary
            Flexible(child: _buildCompactSummary()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSummary() {
    final fontSize = Responsive.bodyFontSize;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(
                'TL Cân:', '${_numberFormat.format(_grossWeight)} kg',
                fontSize: fontSize),
            _buildSummaryRow(
                'Trừ bì:', '${_numberFormat.format(_deduction)} kg',
                fontSize: fontSize),
            Divider(height: 4, color: Colors.teal.shade200),
            _buildSummaryRow(
                'TL Tịnh:', '${_numberFormat.format(_netWeight)} kg',
                fontSize: fontSize, isBold: true, color: Colors.teal.shade700),
            _buildSummaryRow('Số lượng:',
                '${int.tryParse(_quantityController.text) ?? 1} con',
                fontSize: fontSize),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {double fontSize = 12, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize - 1,
                  color: Colors.grey.shade700,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize - 1,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  // ==================== INVOICE DETAILS SECTION ====================
  Widget _buildInvoiceDetailsSection(BuildContext context) {
    final fontSize = Responsive.bodyFontSize;
    final spacing = Responsive.spacing;
    const fieldHeight = 40.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '📝 THÔNG TIN PHIẾU NHẬP CHỢ',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Save button in header
                  ElevatedButton.icon(
                    onPressed: () => _saveInvoice(context),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Lưu (F4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Form fields - 4 rows layout with equal height
            Expanded(
              child: Column(
                children: [
                  // Row 1: Khách hàng
                  _buildRowLabel('Khách hàng', fontSize),
                  Expanded(
                    child: _buildPartnerField(context, fontSize: fontSize),
                  ),
                  const SizedBox(height: 2),
                  // Row 2: Loại heo
                  _buildRowLabel('Loại heo', fontSize),
                  Expanded(
                    child: _buildPigTypeField(context, fontSize: fontSize),
                  ),
                  const SizedBox(height: 2),
                  // Row 3: TL + SL + Trừ bì
                  Row(
                    children: [
                      Expanded(child: _buildRowLabel('TL (kg)', fontSize)),
                      const SizedBox(width: 4),
                      SizedBox(width: 50, child: _buildRowLabel('SL', fontSize)),
                      const SizedBox(width: 4),
                      SizedBox(width: 50, child: _buildRowLabel('Trừ bì', fontSize)),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactTextField(
                            controller: _scaleInputController,
                            focusNode: _scaleInputFocus,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 50,
                          child: _buildCompactTextField(
                            controller: _quantityController,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 50,
                          child: _buildCompactTextField(
                            controller: _deductionController,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 4: Ghi chú
                  _buildRowLabel('Ghi chú', fontSize),
                  Expanded(
                    child: _buildCompactTextField(
                      controller: _noteController,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowLabel(String label, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize - 1,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTableLabel(String label, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize - 1,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required double fontSize,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildPartnerField(BuildContext context, {required double fontSize}) {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        return Autocomplete<PartnerEntity>(
          displayStringForOption: (p) => p.name,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return partners;
            return partners.where((p) => p.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (partner) {
            setState(() => _selectedPartner = partner);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                labelText: 'Khách hàng',
                labelStyle: TextStyle(fontSize: fontSize - 1),
                prefixIcon: const Icon(Icons.person, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPigTypeField(BuildContext context, {required double fontSize}) {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snapshot) {
        final pigTypes = snapshot.data ?? [];
        return Autocomplete<PigTypeEntity>(
          displayStringForOption: (p) => p.name,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return pigTypes;
            return pigTypes.where((p) => p.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (pigType) {
            setState(() {
              _pigTypeController.text = pigType.name;
            });
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            _pigTypeController.text = textController.text;
            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                labelText: 'Loại heo',
                labelStyle: TextStyle(fontSize: fontSize - 1),
                prefixIcon: const Icon(Icons.pets, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== SAVED INVOICES GRID ====================
  Widget _buildSavedInvoicesGrid(BuildContext context) {
    final fontSize = Responsive.bodyFontSize;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '📋 PHIẾU NHẬP CHỢ ĐÃ LƯU HÔM NAY',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Grid
            Expanded(
              child: StreamBuilder<List<InvoiceEntity>>(
                stream: _invoiceRepo.watchInvoices(type: 3, daysAgo: 0),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invoices = snapshot.data!
                    ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
                  if (invoices.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có phiếu nhập chợ nào hôm nay',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: fontSize),
                      ),
                    );
                  }

                  return _buildInvoiceDataGrid(invoices, fontSize);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDataGrid(List<InvoiceEntity> invoices, double fontSize) {
    final headerStyle = TextStyle(
      fontSize: fontSize - 1,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final cellStyle = TextStyle(fontSize: fontSize - 1);

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.shade400,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text('#', style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: _buildSearchableHeader(
                      'Khách hàng', 'partner', headerStyle)),
              SizedBox(
                  width: 70,
                  child: _buildSearchableHeader('SL', 'quantity', headerStyle)),
              SizedBox(
                  width: 80,
                  child: Text('TL Tịnh',
                      style: headerStyle, textAlign: TextAlign.right)),
              SizedBox(
                  width: 100,
                  child: Text('Thành tiền',
                      style: headerStyle, textAlign: TextAlign.right)),
              const SizedBox(width: 60),
            ],
          ),
        ),

        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final isEven = index % 2 == 0;

              // Apply search filters
              if (!_matchesSearchFilters(inv)) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isEven ? Colors.grey.shade50 : Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                        width: 30,
                        child: Text('${index + 1}', style: cellStyle)),
                    Expanded(
                        flex: 2,
                        child: Text(inv.partnerName ?? '-', style: cellStyle)),
                    SizedBox(
                        width: 70,
                        child: Text('${inv.totalQuantity}', style: cellStyle)),
                    SizedBox(
                        width: 80,
                        child: Text(
                          _numberFormat.format(inv.netWeight),
                          style: cellStyle,
                          textAlign: TextAlign.right,
                        )),
                    SizedBox(
                        width: 100,
                        child: Text(
                          _currencyFormat.format(inv.finalAmount),
                          style:
                              cellStyle.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        )),
                    SizedBox(
                      width: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit,
                                size: 16, color: Colors.blue.shade600),
                            onPressed: () => _loadInvoiceToForm(inv),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Sửa',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete,
                                size: 16, color: Colors.red.shade600),
                            onPressed: () => _deleteInvoice(context, inv),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Xóa',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Footer - Totals
        _buildInvoiceTotalsRow(invoices, fontSize),
      ],
    );
  }

  Widget _buildSearchableHeader(
      String label, String columnKey, TextStyle style) {
    final isActive = _activeSearchColumns.contains(columnKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeSearchColumns.remove(columnKey);
          } else {
            _activeSearchColumns.add(columnKey);
          }
        });
      },
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Icon(
            isActive ? Icons.search_off : Icons.search,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  bool _matchesSearchFilters(InvoiceEntity inv) {
    if (_activeSearchColumns.contains('partner') &&
        _searchPartnerController.text.isNotEmpty) {
      if (!(inv.partnerName ?? '')
          .toLowerCase()
          .contains(_searchPartnerController.text.toLowerCase())) {
        return false;
      }
    }
    if (_activeSearchColumns.contains('quantity') &&
        _searchQuantityController.text.isNotEmpty) {
      if (inv.totalQuantity.toString() != _searchQuantityController.text) {
        return false;
      }
    }
    return true;
  }

  Widget _buildInvoiceTotalsRow(List<InvoiceEntity> invoices, double fontSize) {
    final totalWeight =
        invoices.fold<double>(0, (sum, inv) => sum + inv.netWeight);
    final totalAmount =
        invoices.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final totalQuantity =
        invoices.fold<int>(0, (sum, inv) => sum + inv.totalQuantity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30),
          Expanded(
            flex: 2,
            child: Text(
              'TỔNG: ${invoices.length} phiếu',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '$totalQuantity',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              _numberFormat.format(totalWeight),
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _currencyFormat.format(totalAmount),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  // ==================== DEBT SECTION ====================
  Widget _buildDebtSection(BuildContext context) {
    final hasPartner = _selectedPartner != null;
    final partnerName = _selectedPartner?.name ?? 'Chưa chọn khách hàng';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border(top: BorderSide(color: Colors.teal.shade300, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // CÔNG NỢ label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '💰 CÔNG NỢ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          // Partner name
          Text(
            partnerName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: hasPartner ? Colors.black : Colors.grey,
            ),
          ),
          const Spacer(),
          if (hasPartner) ...[
            // Payment method chips
            _buildPaymentChip('T.Mặt', 0, Colors.green),
            const SizedBox(width: 2),
            _buildPaymentChip('C.Khoản', 1, Colors.blue),
            const SizedBox(width: 2),
            _buildPaymentChip('Nợ', 2, Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String label, int method, Color color) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ==================== SAVE BUTTON ====================
  Widget _buildSaveButton(BuildContext context) {
    final canSave = _grossWeight > 0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: canSave ? () => _saveInvoice(context) : null,
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Lưu (F4)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================
  void _saveInvoice(BuildContext context) async {
    if (_grossWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập trọng lượng trước khi lưu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate invoice code
    final invoiceCode = await _invoiceRepo.generateInvoiceCode(3);

    // Create invoice - Chỉ lưu thông tin cơ bản (không tính tiền)
    final invoice = InvoiceEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceCode: invoiceCode,
      type: 3, // Nhập chợ
      partnerId: _selectedPartner?.id,
      partnerName: _selectedPartner?.name,
      totalWeight: _netWeight, // Lưu TL Tịnh
      totalQuantity: int.tryParse(_quantityController.text) ?? 1,
      pricePerKg: 0, // Không tính giá
      deduction: _deduction,
      discount: 0, // Không tính chiết khấu
      finalAmount: 0, // Không tính tiền
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      createdDate: DateTime.now(),
    );

    await _invoiceRepo.createInvoice(invoice);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu phiếu nhập chợ!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _scaleInputController.clear();
      _pigTypeController.clear();
      _noteController.clear();
      _priceController.clear();
      _quantityController.text = '1';
      _deductionController.text = '0';
      _discountController.text = '0';
      _selectedPartner = null;
      _selectedPaymentMethod = 0;
    });
    _scaleInputFocus.requestFocus();
  }

  void _loadInvoiceToForm(InvoiceEntity inv) {
    setState(() {
      _scaleInputController.text = inv.totalWeight.toString();
      _priceController.text = inv.pricePerKg.toStringAsFixed(0);
      _quantityController.text = inv.totalQuantity.toString();
      _deductionController.text = inv.deduction.toString();
      _discountController.text = inv.discount.toStringAsFixed(0);
      _noteController.text = inv.note ?? '';
    });
  }

  void _deleteInvoice(BuildContext context, InvoiceEntity inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa phiếu nhập chợ #${inv.invoiceCode} (${inv.partnerName ?? "Không tên"})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _invoiceRepo.deleteInvoice(inv.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa phiếu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
