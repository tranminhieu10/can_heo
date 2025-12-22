import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/utils/responsive.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/farm.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../domain/repositories/i_farm_repository.dart';
import '../../../data/local/database.dart';
import '../../../injection_container.dart';
import '../../common/widgets/scale_connection_status.dart';
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
          create: (_) => sl<PartnerBloc>()
            ..add(const LoadPartners(true)), // Load NCC (suppliers)
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
  final TextEditingController _scaleInputController =
      TextEditingController(); // TL Chợ
  final TextEditingController _farmWeightController =
      TextEditingController(); // TL Trại
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _farmNameController =
      TextEditingController(); // Trại
  final TextEditingController _batchNumberController =
      TextEditingController(); // Lô
  final TextEditingController _deductionController =
      TextEditingController(text: '0');
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  final TextEditingController _transportFeeController =
      TextEditingController(text: '0'); // Cước xe
  final TextEditingController _paymentAmountController =
      TextEditingController(text: '0'); // Thanh toán
  final TextEditingController _debtPaymentController =
      TextEditingController(); // Trả nợ NCC

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
  FarmEntity? _selectedFarm;
  final _invoiceRepo = sl<IInvoiceRepository>();
  final _farmRepo = sl<IFarmRepository>();
  final _db = sl<AppDatabase>();

  // Track which search columns are visible
  final Set<String> _activeSearchColumns = {};

  // Panel ratio for resizable layout (default 1/3 for form)
  double _panelRatio = 0.33;
  static const double _minPanelRatio = 0.2;
  static const double _maxPanelRatio = 0.5;

  // Payment
  int _selectedPaymentMethod =
      0; // 0 = Tiền mặt, 1 = Chuyển khoản, 2 = Nợ, 3 = Trả nợ

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
    _farmWeightController.dispose();
    _pigTypeController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _farmNameController.dispose();
    _batchNumberController.dispose();
    _deductionController.dispose();
    _discountController.dispose();
    _transportFeeController.dispose();
    _paymentAmountController.dispose();
    _debtPaymentController.dispose();
    _searchPartnerController.dispose();
    _searchQuantityController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _farmWeight =>
      double.tryParse(_farmWeightController.text.replaceAll(',', '.')) ?? 0;
  double get _marketWeight =>
      double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
  double get _haoWeight =>
      (_farmWeight - _marketWeight).clamp(0, double.infinity);
  double get _deduction => double.tryParse(_deductionController.text) ?? 0;
  double get _netWeight => _marketWeight; // TL Chợ is the net weight
  double get _pricePerKg =>
      double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _subtotal => _marketWeight * _pricePerKg;
  double get _transportFee =>
      double.tryParse(_transportFeeController.text.replaceAll(',', '')) ?? 0;
  double get _totalImport => _subtotal + _transportFee;
  double get _paymentAmount =>
      double.tryParse(_paymentAmountController.text.replaceAll(',', '')) ?? 0;
  double get _debtAmount =>
      (_totalImport - _paymentAmount).clamp(0, double.infinity);
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
            title: const Row(
              children: [
                Text('Phiếu Nhập Chợ'),
                SizedBox(width: 12),
                ScaleConnectionStatus(),
              ],
            ),
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

              final padding = Responsive.spacing;
              // Chiều cao form tùy theo screen size (đồng bộ với xuất chợ)
              final formHeight = Responsive.screenType == ScreenType.desktop27
                  ? 400.0
                  : Responsive.screenType == ScreenType.desktop24
                      ? 380.0
                      : Responsive.screenType == ScreenType.laptop15
                          ? 360.0
                          : 340.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // ========== PHẦN 1: Thông tin phiếu - chiều cao cố định, rộng 60% ==========
                    SizedBox(
                      height: formHeight,
                      child: Row(
                        children: [
                          // Bên trái: Form thông tin phiếu - 60%
                          Expanded(
                            flex: 6,
                            child: _buildInvoiceDetailsSection(context),
                          ),
                          const SizedBox(width: 8),
                          // Bên phải: để trống - 40%
                          const Expanded(
                            flex: 4,
                            child: SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ========== PHẦN 2: Phiếu đã lưu (60%) + Công nợ (40%) ==========
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bên trái: Phiếu đã lưu - 60%
                          Expanded(
                            flex: 6,
                            child: _buildSavedInvoicesGrid(context),
                          ),
                          const SizedBox(width: 8),
                          // Bên phải: Công nợ - 40%
                          Expanded(
                            flex: 4,
                            child: _buildDebtSection(context),
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
                'TL Cân:', '${_numberFormat.format(_marketWeight)} kg',
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

            // Form fields - 5 rows layout
            Expanded(
              child: Column(
                children: [
                  // Row 1: Nhà cung cấp + Trại + Lô
                  _buildRowLabels(['Nhà cung cấp', 'Trại', 'Lô'], fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildPartnerField(context,
                                fontSize: fontSize)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildFarmDropdown(fontSize: fontSize),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildCompactTextField(
                            controller: _batchNumberController,
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 2: Loại heo + Tồn chợ + Số lượng
                  _buildRowLabels(
                      ['Loại heo', 'Tồn chợ', 'Số lượng'], fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildPigTypeField(context,
                                fontSize: fontSize)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildInventoryDisplayField()),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildQuantityField(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 3: TL Trại + TL Chợ + Chênh lệch
                  _buildRowLabels(
                      ['TL Trại (kg)', 'TL Chợ (kg)', 'Chênh lệch (kg)'],
                      fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactTextField(
                            controller: _farmWeightController,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 4),
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
                        // Hao (read-only calculated: TL Trại - TL Chợ)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: _haoWeight > 0
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _haoWeight > 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300),
                            ),
                            child: Text(
                              _numberFormat.format(_haoWeight),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _haoWeight > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 4: Đơn giá + Thành tiền + Cước xe
                  _buildRowLabels(
                      ['Đơn giá (đ/kg)', 'Thành tiền', 'Cước xe'], fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        // Đơn giá
                        Expanded(
                          child: _buildCompactTextField(
                            controller: _priceController,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Thành tiền (read-only: TL Chợ * Đơn giá)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              _currencyFormat.format(_subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Cước xe
                        Expanded(
                          child: _buildCompactTextField(
                            controller: _transportFeeController,
                            fontSize: fontSize,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 5: Tổng tiền | Thanh toán | Công nợ
                  _buildRowLabels(
                      ['Tổng tiền', 'Thanh toán', 'Công nợ'], fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        // Tổng tiền (read-only: Thành tiền + Cước xe)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Text(
                              _currencyFormat.format(_totalImport),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Thanh toán
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              _currencyFormat.format(_paymentAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Công nợ (read-only: Tổng tiền - Thanh toán)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: _debtAmount > 0
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _debtAmount > 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300),
                            ),
                            child: Text(
                              _currencyFormat.format(_debtAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _debtAmount > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 6: Ghi chú (full width)
                  _buildRowLabels(['Ghi chú', '', ''], fontSize),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRowLabels(List<String> labels, double fontSize) {
    return Row(
      children: labels
          .map((label) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ))
          .expand((w) => [w, const SizedBox(width: 4)])
          .toList()
        ..removeLast(),
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildFarmDropdown({required double fontSize}) {
    if (_selectedPartner == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
        ),
        child: Text(
          'Chọn Nhà CC trước',
          style: TextStyle(fontSize: fontSize, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<List<FarmEntity>>(
      stream: _farmRepo.watchFarmsByPartner(_selectedPartner!.id),
      builder: (context, snapshot) {
        final farms = snapshot.data ?? [];

        if (farms.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade400),
              borderRadius: BorderRadius.circular(6),
              color: Colors.orange.shade50,
            ),
            child: Text(
              'Chưa có trại',
              style:
                  TextStyle(fontSize: fontSize, color: Colors.orange.shade700),
            ),
          );
        }

        return DropdownButtonFormField<FarmEntity>(
          value: _selectedFarm,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.home_work, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: TextStyle(fontSize: fontSize, color: Colors.black),
          hint: Text('Chọn trại', style: TextStyle(fontSize: fontSize)),
          items: farms.map((farm) {
            return DropdownMenuItem<FarmEntity>(
              value: farm,
              child: Text(farm.name, style: TextStyle(fontSize: fontSize)),
            );
          }).toList(),
          onChanged: (farm) {
            setState(() {
              _selectedFarm = farm;
            });
          },
        );
      },
    );
  }

  Widget _buildPartnerField(BuildContext context, {required double fontSize}) {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        return DropdownButtonFormField<PartnerEntity>(
          value: _selectedPartner,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          hint: const Text('Chọn NCC', style: TextStyle(fontSize: 13)),
          items: partners.map((partner) {
            return DropdownMenuItem<PartnerEntity>(
              value: partner,
              child: Text(partner.name, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (partner) {
            setState(() {
              _selectedPartner = partner;
              _selectedFarm = null; // Reset farm khi đổi NCC
            });
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
            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.pets, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _pigTypeController.text = value;
                });
              },
            );
          },
        );
      },
    );
  }

  // Tồn chợ = Nhập chợ (3) + Xuất kho (1) - Xuất chợ (2) - Nhập kho (0)
  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainer(0);
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest4(
        _invoiceRepo.watchInvoices(type: 3), // Nhập chợ từ NCC (+)
        _invoiceRepo.watchInvoices(type: 1), // Xuất kho ra chợ (+)
        _invoiceRepo.watchInvoices(type: 2), // Xuất chợ bán (-)
        _invoiceRepo.watchInvoices(type: 0), // Nhập kho hàng thừa (-)
        (a, b, c, d) => [a, b, c, d],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final importMarket = snapshot.data![0]; // Type 3: Nhập chợ từ NCC (+)
        final exportBarn = snapshot.data![1];   // Type 1: Xuất kho ra chợ (+)
        final exportMarket = snapshot.data![2]; // Type 2: Xuất chợ bán (-)
        final importBarn = snapshot.data![3];   // Type 0: Nhập kho hàng thừa (-)
        
        int available = 0;
        
        // + Nhập chợ từ NCC (Type 3)
        for (final inv in importMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available += item.quantity;
          }
        }
        
        // + Xuất kho ra chợ (Type 1)
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available += item.quantity;
          }
        }
        
        // - Xuất chợ bán (Type 2)
        for (final inv in exportMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available -= item.quantity;
          }
        }
        
        // - Nhập kho hàng thừa (Type 0)
        for (final inv in importBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available -= item.quantity;
          }
        }
        
        return _buildInventoryContainer(available);
      },
    );
  }

  Widget _buildInventoryContainer(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: qty > 0 ? Colors.green.shade50 : Colors.grey.shade100,
        border: Border.all(
            color: qty > 0 ? Colors.green.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        '$qty con',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: qty > 0 ? Colors.green[700] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Nút giảm
          InkWell(
            onTap: () {
              final current = int.tryParse(_quantityController.text) ?? 1;
              if (current > 1) {
                setState(() {
                  _quantityController.text = (current - 1).toString();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: const Center(
                child: Icon(Icons.remove, size: 16),
              ),
            ),
          ),
          // Ô nhập số
          Expanded(
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Nút tăng
          InkWell(
            onTap: () {
              final current = int.tryParse(_quantityController.text) ?? 1;
              setState(() {
                _quantityController.text = (current + 1).toString();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 16),
              ),
            ),
          ),
        ],
      ),
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
                    '📋 PHIẾU NHẬP CHỢ ĐÃ LƯU',
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
    final headerStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final cellStyle = const TextStyle(fontSize: 12);
    final dateFormat = DateFormat('HH:mm');

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.shade400,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('#',
                      style: headerStyle, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('Giờ',
                      style: headerStyle, textAlign: TextAlign.center)),
              Expanded(flex: 4, child: Text('NCC', style: headerStyle)),
              Expanded(flex: 3, child: Text('Trại', style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Lô',
                      style: headerStyle, textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text('Loại', style: headerStyle)),
              Expanded(
                  flex: 2,
                  child: Text('SL',
                      style: headerStyle, textAlign: TextAlign.center)),
              Expanded(
                  flex: 3,
                  child: Text('TL Trại',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('TL Chợ',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 2,
                  child: Text('Hao',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('Đơn giá',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('Thành tiền',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('Cước xe',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('Tổng nhập',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('T.Toán',
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  flex: 3,
                  child: Text('Công nợ',
                      style: headerStyle, textAlign: TextAlign.right)),
              const SizedBox(width: 50),
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

              // Lấy thông tin từ invoice theo cách lưu mới:
              // - totalWeight = TL Chợ
              // - deduction = TL Trại (lưu trong truckCost DB)
              // - discount = Cước xe
              // - details[0].pigType = Loại heo
              // - details[0].batchNumber = Lô
              String farmName = '-';
              String batchNumber = '-';
              String pigType = '-';

              // Lấy loại heo và lô từ details
              if (inv.details.isNotEmpty) {
                pigType = inv.details.first.pigType ?? '-';
                batchNumber = inv.details.first.batchNumber ?? '-';
              }

              double farmWeight =
                  inv.deduction; // TL Trại (lưu trong deduction/truckCost)
              double marketWeight = inv.totalWeight; // TL Chợ
              double hao = (farmWeight - marketWeight)
                  .clamp(0, double.infinity); // Hao = TL Trại - TL Chợ
              double subtotal = marketWeight *
                  inv.pricePerKg; // Thành tiền = TL Chợ × Đơn giá
              double transportFee =
                  inv.discount; // Cước xe (lưu trong discount)
              double totalImport =
                  subtotal + transportFee; // Tổng nhập = Thành tiền + Cước xe
              double paid = inv.paidAmount; // Thanh toán
              double debt =
                  (totalImport - paid).clamp(0, double.infinity); // Công nợ

              // Parse note format: "Trại: xxx | ..."
              if (inv.note != null && inv.note!.isNotEmpty) {
                final parts = inv.note!.split('|');
                for (var part in parts) {
                  final trimmed = part.trim();
                  if (trimmed.startsWith('Trại:')) {
                    farmName = trimmed.replaceFirst('Trại:', '').trim();
                  }
                }
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
                    Expanded(
                        flex: 1,
                        child: Text('${index + 1}',
                            style: cellStyle, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text(dateFormat.format(inv.createdDate),
                            style: cellStyle, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 4,
                        child: Text(inv.partnerName ?? '-',
                            style: cellStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 3,
                        child: Text(farmName,
                            style: cellStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 2,
                        child: Text(batchNumber,
                            style: cellStyle, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text(pigType,
                            style: cellStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 2,
                        child: Text('${inv.totalQuantity}',
                            style: cellStyle, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text(_numberFormat.format(farmWeight),
                            style: cellStyle, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_numberFormat.format(marketWeight),
                            style: cellStyle, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 2,
                        child: Text(_numberFormat.format(hao),
                            style: cellStyle.copyWith(color: Colors.red),
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(inv.pricePerKg),
                            style: cellStyle, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(subtotal),
                            style: cellStyle, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(transportFee),
                            style: cellStyle, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(totalImport),
                            style:
                                cellStyle.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(paid),
                            style: cellStyle.copyWith(color: Colors.green),
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text(_formatShortCurrency(debt),
                            style: cellStyle.copyWith(
                                color: debt > 0 ? Colors.red : Colors.black),
                            textAlign: TextAlign.right)),
                    SizedBox(
                      width: 50,
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

  String _formatShortCurrency(double value) {
    // Hiển thị đầy đủ giá trị tiền tệ với dấu phân cách hàng nghìn
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value);
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
    // Tính theo cách lưu mới:
    // - totalWeight = TL Chợ
    // - deduction = TL Trại (lưu trong truckCost DB)
    // - discount = Cước xe
    double totalMarketWeight = 0;
    double totalFarmWeight = 0;
    double totalHao = 0;
    double totalSubtotal = 0;
    double totalTransportFee = 0;
    double totalImport = 0;
    double totalPaid = 0;
    double totalDebt = 0;
    int totalQuantity = 0;

    for (final inv in invoices) {
      final marketWeight = inv.totalWeight; // TL Chợ
      final farmWeight = inv.deduction; // TL Trại
      final hao = (farmWeight - marketWeight).clamp(0.0, double.infinity);
      final subtotal = marketWeight * inv.pricePerKg; // Thành tiền
      final transportFee = inv.discount; // Cước xe
      final import_ = subtotal + transportFee; // Tổng nhập
      final debt = (import_ - inv.paidAmount).clamp(0.0, double.infinity);

      totalMarketWeight += marketWeight;
      totalFarmWeight += farmWeight;
      totalHao += hao;
      totalSubtotal += subtotal;
      totalTransportFee += transportFee;
      totalImport += import_;
      totalPaid += inv.paidAmount;
      totalDebt += debt;
      totalQuantity += inv.totalQuantity;
    }

    final cellStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('', style: cellStyle)),
          Expanded(flex: 2, child: Text('', style: cellStyle)),
          Expanded(
              flex: 4,
              child: Text('TỔNG: ${invoices.length} phiếu', style: cellStyle)),
          Expanded(flex: 3, child: Text('', style: cellStyle)),
          Expanded(flex: 2, child: Text('', style: cellStyle)),
          Expanded(flex: 3, child: Text('', style: cellStyle)),
          Expanded(
              flex: 2,
              child: Text('$totalQuantity',
                  style: cellStyle, textAlign: TextAlign.center)),
          Expanded(
              flex: 3,
              child: Text(_numberFormat.format(totalFarmWeight),
                  style: cellStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(_numberFormat.format(totalMarketWeight),
                  style: cellStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text(_numberFormat.format(totalHao),
                  style: cellStyle.copyWith(color: Colors.red),
                  textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text('', style: cellStyle)),
          Expanded(
              flex: 3,
              child: Text(_formatShortCurrency(totalSubtotal),
                  style: cellStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(_formatShortCurrency(totalTransportFee),
                  style: cellStyle, textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(_formatShortCurrency(totalImport),
                  style: cellStyle.copyWith(color: Colors.teal.shade800),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(_formatShortCurrency(totalPaid),
                  style: cellStyle.copyWith(color: Colors.green),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 3,
              child: Text(_formatShortCurrency(totalDebt),
                  style: cellStyle.copyWith(
                      color: totalDebt > 0 ? Colors.red : Colors.black),
                  textAlign: TextAlign.right)),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  // ==================== DEBT SECTION ====================
  Widget _buildDebtSection(BuildContext context) {
    final hasPartner = _selectedPartner != null;
    final partnerId = _selectedPartner?.id;
    final partnerName = _selectedPartner?.name ?? 'Chưa chọn NCC';

    return FutureBuilder<Map<String, dynamic>>(
      future:
          hasPartner ? _calculateSupplierDebt(partnerId!) : Future.value({}),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final totalDebt = (debtInfo['totalDebt'] as num?)?.toDouble() ?? 0.0;
        final totalPaid = (debtInfo['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        // Hiển thị dọc: Header + Summary + Thanh toán + Trả nợ + Lịch sử
        return Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.teal.shade300, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Title + NCC
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '💰 CÔNG NỢ NCC',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            partnerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: hasPartner ? Colors.black : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 2: Tổng số (3 columns)
                    Row(
                      children: [
                        Expanded(
                          child: _buildDebtSummaryChipLarge(
                              'Tổng nợ', totalDebt, Colors.orange),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildDebtSummaryChipLarge(
                              'Đã trả', totalPaid, Colors.green),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildDebtSummaryChipLarge('Còn nợ', remaining,
                              remaining > 0 ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 3: Thanh toán
                    if (hasPartner) ...[
                      // Label Thanh toán
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Thanh toán',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: _selectedPaymentMethod < 2
                                  ? () => _saveSupplierPayment(context)
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Xác nhận',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Hình thức thanh toán
                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildPaymentChip('Tiền mặt', 0, Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPaymentChip(
                                'Chuyển khoản', 1, Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nhập tiền
                      SizedBox(
                        height: 32,
                        child: TextField(
                          controller: _paymentAmountController,
                          keyboardType: TextInputType.number,
                          enabled: _selectedPaymentMethod < 2,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            suffixText: 'đ',
                            suffixStyle: const TextStyle(fontSize: 10),
                            hintText: 'Nhập tiền',
                            hintStyle: const TextStyle(fontSize: 11),
                            filled: _selectedPaymentMethod >= 2,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Row 4: Trả nợ
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Trả nợ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 32,
                            child: FilledButton(
                              onPressed: _selectedPaymentMethod >= 3
                                  ? () => _saveSupplierPayment(context)
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Xác nhận',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Hình thức trả nợ - Tiền mặt + Chuyển khoản
                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildPaymentChip('Tiền mặt', 3, Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPaymentChip(
                                'Chuyển khoản', 4, Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nhập tiền trả nợ
                      SizedBox(
                        height: 32,
                        child: TextField(
                          controller: _debtPaymentController,
                          keyboardType: TextInputType.number,
                          enabled: _selectedPaymentMethod >= 3,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            suffixText: 'đ',
                            suffixStyle: const TextStyle(fontSize: 10),
                            hintText: 'Trả nợ NCC',
                            hintStyle: const TextStyle(fontSize: 11),
                            filled: _selectedPaymentMethod < 3,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Lịch sử thanh toán
              if (hasPartner)
                Expanded(
                  child: _buildPaymentHistoryList(partnerId!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebtSummaryChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w500)),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryChipLarge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList(String partnerId) {
    return FutureBuilder<List<Transaction>>(
      future: _db.transactionsDao.watchTransactionsByPartner(partnerId).first,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Chưa có giao dịch nào',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          );
        }

        final transactions = snapshot.data!
            .where((tx) => tx.type == 1) // Chi - trả tiền cho NCC
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ngày',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Loại',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Số tiền',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Ghi chú',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // Data rows
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: transactions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isEven = index % 2 == 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        // Ngày
                        Expanded(
                          flex: 3,
                          child: Text(
                            DateFormat('dd/MM HH:mm')
                                .format(tx.transactionDate),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        // Loại
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tx.paymentMethod == 0
                                  ? Colors.green.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.paymentMethod == 0 ? 'T.Mặt' : 'C.Khoản',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tx.paymentMethod == 0
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Số tiền
                        Expanded(
                          flex: 3,
                          child: Text(
                            _currencyFormat.format(tx.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ghi chú
                        Expanded(
                          flex: 4,
                          child: Text(
                            tx.note ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculateSupplierDebt(String partnerId) async {
    // Get all invoices for this supplier (type = 3 - Nhập chợ)
    final invoices = await _invoiceRepo.watchInvoices(type: 3).first;
    final partnerInvoices =
        invoices.where((inv) => inv.partnerId == partnerId).toList();

    double totalDebt = 0;
    for (final inv in partnerInvoices) {
      // Tính thành tiền = TL Chợ × Đơn giá + Cước xe
      final marketWeight = inv.totalWeight;
      final subtotal = marketWeight * inv.pricePerKg;
      final transportFee = inv.discount;
      totalDebt += subtotal + transportFee;
    }

    // Get all payments (transactions) for this supplier
    final transactions =
        await _db.transactionsDao.watchTransactionsByPartner(partnerId).first;
    double totalPaid = 0;
    for (final tx in transactions) {
      if (tx.type == 1) {
        // Chi (trả tiền cho NCC)
        totalPaid += tx.amount;
      }
    }

    return {
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'remaining': (totalDebt - totalPaid).clamp(0, double.infinity),
    };
  }

  Future<void> _saveSupplierPayment(BuildContext context) async {
    if (_selectedPartner == null) return;

    final partnerId = _selectedPartner!.id;

    // Get amount based on payment method
    final amount = _selectedPaymentMethod >= 3
        ? (double.tryParse(_debtPaymentController.text) ?? 0)
        : (double.tryParse(_paymentAmountController.text) ?? 0);

    // If "Nợ" is selected for payment method, we don't create a transaction
    if (_selectedPaymentMethod == 2) {
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ Vui lòng nhập số tiền'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // All payment methods save to transaction history with type = 1 (Chi - trả tiền NCC)
      String note;
      int actualPaymentMethod; // Payment method to save in DB (0 or 1)

      switch (_selectedPaymentMethod) {
        case 0:
          note = 'Thanh toán NCC tiền mặt';
          actualPaymentMethod = 0;
          break;
        case 1:
          note = 'Thanh toán NCC chuyển khoản';
          actualPaymentMethod = 1;
          break;
        case 3:
          note = 'Trả nợ NCC tiền mặt';
          actualPaymentMethod = 0;
          break;
        case 4:
          note = 'Trả nợ NCC chuyển khoản';
          actualPaymentMethod = 1;
          break;
        default:
          note = 'Thanh toán NCC';
          actualPaymentMethod = 0;
      }

      await _db.transactionsDao.createTransaction(
        TransactionsCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          partnerId: Value(partnerId),
          invoiceId: const Value(null),
          amount: Value(amount),
          type: const Value(1), // 1 = Chi (trả tiền cho NCC)
          paymentMethod: Value(
              actualPaymentMethod), // Lưu 0 (tiền mặt) hoặc 1 (chuyển khoản)
          transactionDate: Value(DateTime.now()),
          note: Value(note),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Đã ghi nhận: ${_currencyFormat.format(amount)} - $note'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // Reset các ô nhập tiền
    setState(() {
      _debtPaymentController.clear();
      _paymentAmountController.text = '0';
    });
  }

  void _showPaymentHistoryDialog(
      BuildContext context, String partnerId, String partnerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Lịch sử thanh toán NCC - $partnerName',
                    style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: _buildPaymentHistoryTable(partnerId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTable(String partnerId) {
    return StreamBuilder<List<Transaction>>(
      stream: _db.transactionsDao.watchTransactionsByPartner(partnerId),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        // Lọc chỉ lấy giao dịch Chi (type = 1) và sắp xếp mới nhất trước
        final filtered = transactions.where((t) => t.type == 1).toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        if (filtered.isEmpty) {
          return Container(
            color: Colors.grey.shade50,
            child: const Center(
              child: Text('Chưa có giao dịch',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          );
        }

        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                height: 24,
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 120,
                        child: Text('Ngày',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(
                        width: 80,
                        child: Text('Loại',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Số tiền',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                    SizedBox(
                        width: 100,
                        child: Text('Ghi chú',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    final typeLabel = switch (t.paymentMethod) {
                      0 => 'T.Mặt',
                      1 => 'C.Khoản',
                      3 => 'Trả nợ',
                      _ => '?',
                    };
                    final typeColor = switch (t.paymentMethod) {
                      0 => Colors.green,
                      1 => Colors.blue,
                      3 => Colors.purple,
                      _ => Colors.grey,
                    };

                    return Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            index.isEven ? Colors.white : Colors.grey.shade50,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              dateFormat.format(t.transactionDate),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: typeColor,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _currencyFormat.format(t.amount),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              t.note ?? '',
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    final canSave = _marketWeight > 0;
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
    if (_marketWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('⚠️ Vui lòng nhập trọng lượng chợ (TL Chợ) trước khi lưu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate invoice code
    final invoiceCode = await _invoiceRepo.generateInvoiceCode(3);

    // Build note với thông tin Trại và Lô
    final noteBuilder = <String>[];
    if (_selectedFarm != null) {
      noteBuilder.add('Trại: ${_selectedFarm!.name}');
    }
    if (_batchNumberController.text.isNotEmpty) {
      noteBuilder.add('Lô: ${_batchNumberController.text}');
    }
    if (_noteController.text.isNotEmpty) {
      noteBuilder.add(_noteController.text);
    }
    final fullNote = noteBuilder.isNotEmpty ? noteBuilder.join(' | ') : null;

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    // Create invoice với đầy đủ thông tin
    // - totalWeight = TL Chợ (trọng lượng sau cân tại chợ)
    // - deduction = TL Trại (trọng lượng gốc từ trại, lưu vào truckCost trong DB)
    // - discount = Cước xe
    // - finalAmount = Thành tiền (TL Chợ × Đơn giá + Cước xe)
    final invoice = InvoiceEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceCode: invoiceCode,
      type: 3, // Nhập chợ
      partnerId: _selectedPartner?.id,
      partnerName: _selectedPartner?.name,
      totalWeight: _marketWeight, // TL Chợ
      totalQuantity: quantity,
      pricePerKg: _pricePerKg, // Đơn giá
      deduction: _farmWeight, // TL Trại (lưu vào truckCost trong DB)
      discount: _transportFee, // Cước xe
      finalAmount: _totalImport, // Thành tiền + Cước xe
      paidAmount: _paymentAmount, // Số tiền thanh toán
      note: fullNote,
      createdDate: DateTime.now(),
    );

    await _invoiceRepo.createInvoice(invoice);

    // Lưu chi tiết với loại heo
    if (_pigTypeController.text.isNotEmpty) {
      final weighingItem = WeighingItemEntity(
        id: '${invoice.id}_1',
        sequence: 1,
        weight: _marketWeight,
        quantity: quantity,
        time: DateTime.now(),
        batchNumber: _batchNumberController.text.isNotEmpty
            ? _batchNumberController.text
            : null,
        pigType: _pigTypeController.text.trim(),
      );
      await _invoiceRepo.addWeighingItem(invoice.id, weighingItem);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Đã lưu phiếu nhập chợ! TL Trại: ${_numberFormat.format(_farmWeight)}kg, TL Chợ: ${_numberFormat.format(_marketWeight)}kg, Hao: ${_numberFormat.format(_haoWeight)}kg'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _scaleInputController.clear();
      _farmWeightController.clear();
      _pigTypeController.clear();
      _noteController.clear();
      _priceController.clear();
      _quantityController.text = '1';
      _deductionController.text = '0';
      _discountController.text = '0';
      _transportFeeController.text = '0';
      _paymentAmountController.text = '0';
      _batchNumberController.clear();
      _selectedPartner = null;
      _selectedFarm = null;
      _selectedPaymentMethod = 0;
    });
    _scaleInputFocus.requestFocus();
  }

  void _loadInvoiceToForm(InvoiceEntity inv) {
    setState(() {
      _scaleInputController.text = inv.totalWeight.toString(); // TL Chợ
      _farmWeightController.text =
          inv.deduction.toString(); // TL Trại (lưu trong deduction/truckCost)
      _priceController.text = inv.pricePerKg.toStringAsFixed(0);
      _quantityController.text = inv.totalQuantity.toString();
      _transportFeeController.text =
          inv.discount.toStringAsFixed(0); // Cước xe (lưu trong discount)
      _paymentAmountController.text = inv.paidAmount.toStringAsFixed(0);
      _noteController.text = inv.note ?? '';
      // Load loại heo từ details nếu có
      if (inv.details.isNotEmpty) {
        _pigTypeController.text = inv.details.first.pigType ?? '';
        _batchNumberController.text = inv.details.first.batchNumber ?? '';
      }
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
