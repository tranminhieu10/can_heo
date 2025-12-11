import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:async';
import 'package:intl/intl.dart';

import '../../../core/services/scale_service.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../pig_types/pig_types_screen.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../data/local/database.dart'
    hide
        WeighingStarted,
        WeighingItemAdded,
        WeighingItemRemoved,
        WeighingInvoiceUpdated,
        WeighingSaved,
        WeighingScaleDataReceived,
        WeighingEvent;
import '../../../injection_container.dart';
import '../history/invoice_detail_screen.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';

class MarketExportScreen extends StatelessWidget {
  const MarketExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeighingBloc>(
          create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(2)),
        ),
        BlocProvider<PartnerBloc>(
          create: (_) => sl<PartnerBloc>()..add(const LoadPartners(false)),
        ),
      ],
      child: const _MarketExportView(),
    );
  }
}

class _MarketExportView extends StatefulWidget {
  const _MarketExportView();

  @override
  State<_MarketExportView> createState() => _MarketExportViewState();
}

class _MarketExportViewState extends State<_MarketExportView> {
  // Controllers
  final TextEditingController _scaleInputController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
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
  final TextEditingController _searchPigTypeController =
      TextEditingController();
  final TextEditingController _searchQuantityController =
      TextEditingController();

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  PartnerEntity? _selectedPartner;
  final _invoiceRepo = sl<IInvoiceRepository>();
  final _db = sl<AppDatabase>();

  // Track which search columns are visible
  final Set<String> _activeSearchColumns = {};

  // Current weight from scale (locked when user confirms)
  double _lockedWeight = 0;
  bool _isWeightLocked = false;

  // Debt section always visible - shows partner debt when selected
  InvoiceEntity? _lastSavedInvoice;

  // Payment form controllers
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _invoicePaymentAmountController =
      TextEditingController(); // Số tiền thanh toán cho phiếu xuất mới
  int _selectedPaymentMethod = 0; // 0 = Tiền mặt, 1 = Chuyển khoản, 2 = Nợ
  int _selectedDebtPaymentMethod = 0; // 0 = Tiền mặt, 1 = Chuyển khoản

  // Resizable divider positions
  double _leftPanelFlex = 1.0; // Scale section flex factor

  @override
  void initState() {
    super.initState();
    _loadInitialPigType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scaleInputFocus.requestFocus();
    });
  }

  Future<void> _loadInitialPigType() async {
    final types = await sl<IPigTypeRepository>().watchPigTypes().first;
    if (mounted && types.isNotEmpty) {
      setState(() {
        _pigTypeController.text = types.first.name;
      });
    }
  }

  @override
  void dispose() {
    _scaleInputController.dispose();
    _batchNumberController.dispose();
    _pigTypeController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _deductionController.dispose();
    _discountController.dispose();
    _searchPartnerController.dispose();
    _searchPigTypeController.dispose();
    _searchQuantityController.dispose();
    _paymentAmountController.dispose();
    _invoicePaymentAmountController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _grossWeight => _isWeightLocked ? _lockedWeight : 0;
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
            _lockWeight(context),
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            sl<IScaleService>().tare(),
      },
      child: Focus(
        autofocus: true,
        child: BlocListener<WeighingBloc, WeighingState>(
          listener: (context, state) {
            if (state.status == WeighingStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã lưu phiếu xuất chợ!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              if (state.currentInvoice != null) {
                setState(() {
                  _lastSavedInvoice = state.currentInvoice;
                  _invoicePaymentAmountController.text =
                      state.currentInvoice!.finalAmount.toStringAsFixed(0);
                  _paymentAmountController.clear();
                });
              }

              // After saving, don't reset the whole form, just the invoice details
              // The _savePayment will handle resetting payment fields.
              _resetInvoiceFields();
            } else if (state.status == WeighingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Lỗi không xác định'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Phiếu Xuất Chợ'),
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
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // ========== PHẦN 1: Scale + Summary | Invoice Form (Resizable - Fixed Height) ==========
                  SizedBox(
                    height: 280, // Reduced height to prevent overflow
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left side: Scale + Summary
                        Expanded(
                          flex: _leftPanelFlex.round(),
                          child: _buildScaleSection(context),
                        ),
                        // Resizable divider
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                final containerWidth =
                                    MediaQuery.of(context).size.width - 16;
                                final deltaFlex =
                                    details.delta.dx / containerWidth * 4;
                                _leftPanelFlex = (_leftPanelFlex + deltaFlex)
                                    .clamp(0.3, 2.5);
                              });
                            },
                            child: Container(
                              width: 8,
                              color: Colors.grey[300],
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right side: Invoice Details Form
                        Expanded(
                          flex: (3.0 - _leftPanelFlex).round(),
                          child: _buildInvoiceDetailsSection(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ========== PHẦN 2: Phiếu xuất đã lưu ==========
                  Expanded(
                    child: _buildSavedInvoicesGrid(context),
                  ),
                  const SizedBox(height: 4),
                  // ========== PHẦN 3: Debt section (always visible) ==========
                  SizedBox(
                    height: 220, // Reduced height for debt section
                    child: _buildDebtSection(context),
                  ),
                  // Footer
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Phím tắt: [F1] Chốt cân | [F2] Tare | [F4] Lưu phiếu",
                      style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetInvoiceFields() {
    _scaleInputController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    // Don't clear pigType, user might want to enter another of the same type
    _priceController.clear();
    _quantityController.text = '1';
    _deductionController.text = '0';
    _discountController.text = '0';
    setState(() {
      _lockedWeight = 0;
      _isWeightLocked = false;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(2));
    _scaleInputFocus.requestFocus();
  }

  void _resetForm() {
    _resetInvoiceFields();
    _pigTypeController.clear();
     _searchPartnerController.clear();
    _searchPigTypeController.clear();
    _searchQuantityController.clear();
    setState(() {
      _selectedPartner = null;
      _lastSavedInvoice = null;
      _paymentAmountController.clear();
      _invoicePaymentAmountController.clear();
      _selectedPaymentMethod = 0;
      _selectedDebtPaymentMethod = 0;
    });
  }

  void _lockWeight(BuildContext context) {
    final state = context.read<WeighingBloc>().state;
    if (state.isScaleConnected && state.scaleWeight > 0) {
      setState(() {
        _lockedWeight = state.scaleWeight;
        _isWeightLocked = true;
        _updateAutoDiscount();
      });
    }
  }

  void _lockWeightManual() {
    final raw = _scaleInputController.text.trim();
    if (raw.isEmpty) return;

    final weight = double.tryParse(raw.replaceAll(',', '.'));
    if (weight != null && weight > 0) {
      setState(() {
        _lockedWeight = weight;
        _isWeightLocked = true;
        _updateAutoDiscount();
      });
      _scaleInputController.clear();
    }
  }

  void _updateAutoDiscount() {
    final autoDisc = _subtotal - (_subtotal / 1000).floor() * 1000;
    _discountController.text = autoDisc.toStringAsFixed(0);
  }

  void _adjustDeduction(int delta) {
    final current = double.tryParse(_deductionController.text) ?? 0;
    final newValue = (current + delta).clamp(0, double.infinity);
    setState(() {
      _deductionController.text = newValue.toStringAsFixed(0);
      _updateAutoDiscount();
    });
  }

  Widget _buildScaleSection(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final weight = state.scaleWeight;
        final connected = state.isScaleConnected;
        return Card(
          color: _isWeightLocked ? Colors.orange[50] : Colors.blue[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ROW 1: Scale display
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isWeightLocked ? Colors.orange : Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isWeightLocked ? 'ĐÃ CHỐT: ' : 'SỐ CÂN: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _isWeightLocked ? Colors.orange[700] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _isWeightLocked
                            ? _numberFormat.format(_lockedWeight)
                            : (connected ? _numberFormat.format(weight) : 'Mất kết nối'),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _isWeightLocked
                              ? Colors.orange[800]
                              : (connected ? Colors.blue[800] : Colors.red),
                        ),
                      ),
                      Text(
                        ' kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isWeightLocked ? Colors.orange[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ROW 2: TARE and Lock buttons
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: connected ? () => sl<IScaleService>().tare() : null,
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('TARE (F2)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FilledButton(
                          onPressed: (connected && weight > 0) || _scaleInputController.text.isNotEmpty
                              ? () {
                                  if (_isWeightLocked) {
                                    setState(() {
                                      _isWeightLocked = false;
                                      _lockedWeight = 0;
                                    });
                                  } else if (_scaleInputController.text.isNotEmpty) {
                                    _lockWeightManual();
                                  } else {
                                    _lockWeight(context);
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: _isWeightLocked ? Colors.orange : null,
                          ),
                          child: Text(
                            _isWeightLocked ? 'HỦY CHỐT' : 'CHỐT CÂN (F1)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ROW 3: Summary
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildCompactSummary('HEO BÁN', Icons.pets, Colors.orange)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildCompactSummary('KHỐI LƯỢNG', Icons.scale, Colors.blue)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildCompactSummary('TỔNG TIỀN', Icons.attach_money, Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactSummary(String label, IconData icon, Color color) {
    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 2, daysAgo: 0), // Only today
        builder: (context, snapshot) {
          String value = '0';
          if (snapshot.hasData) {
            final todayInvoices = snapshot.data!;
            double totalWeight = 0;
            int totalQuantity = 0;
            double totalAmount = 0;

            for (final inv in todayInvoices) {
              totalWeight += inv.totalWeight;
              totalQuantity += inv.totalQuantity;
              totalAmount += inv.finalAmount;
            }

            if (label.contains('HEO')) {
              value = '$totalQuantity con';
            } else if (label.contains('KHỐI')) {
              value = '${_numberFormat.format(totalWeight)} kg';
            } else {
              value = _currencyFormat.format(totalAmount);
            }
          }

          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'THÔNG TIN PHIẾU XUẤT CHỢ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isWeightLocked
                              ? Colors.orange[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isWeightLocked
                                  ? Icons.check_circle
                                  : Icons.warning,
                              size: 14,
                              color: _isWeightLocked
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isWeightLocked ? 'Đã chốt' : 'Chưa chốt',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isWeightLocked
                                    ? Colors.orange[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: _canSaveInvoice()
                              ? () => _saveInvoice(context)
                              : null,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('LƯU (F4)',
                              style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ROW 1
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildGridTextField(
                      controller: TextEditingController(
                        text: _selectedPartner?.id ?? '',
                      ),
                      label: 'Mã KH',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 2,
                    child: _buildPartnerSelector(context),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildPartnerDebtField(),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // ROW 2
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: _buildPigTypeWithInventory(),
                  ),
                  const SizedBox(width: 6),
                   Flexible(
                    flex: 1,
                    child: _buildGridTextField(
                      controller: _batchNumberController,
                      label: 'Số lô',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildInventoryDisplayField(),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // ROW 3
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildQuantityFieldWithButtons(),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildGridLockedField(
                      label: 'Trọng lượng (kg)',
                      value: _numberFormat.format(_grossWeight),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildDeductionField(),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildGridLockedField(
                      label: 'TL Thực (kg)',
                      value: _numberFormat.format(_netWeight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // ROW 4
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildGridTextField(
                      controller: _priceController,
                      label: 'Đơn giá (đ/kg)',
                      isNumber: true,
                      onChanged: (_) => setState(() => _updateAutoDiscount()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildGridLockedField(
                      label: 'Thành tiền',
                      value: _currencyFormat.format(_subtotal),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildGridTextField(
                      controller: _discountController,
                      label: 'Chiết khấu (đ)',
                      isNumber: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 1,
                    child: _buildGridLockedField(
                      label: 'THỰC THU',
                      value: _currencyFormat.format(_totalAmount),
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // ROW 5
              _buildGridTextField(
                controller: _noteController,
                label: 'Ghi chú',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Build uniform text field for grid
  Widget _buildGridTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : [],
        style: const TextStyle(fontSize: 14),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
          isDense: true,
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // Helper: Build locked field for grid (readonly)
  Widget _buildGridLockedField({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(
          color: highlight ? Colors.blue : Colors.grey[400]!,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: highlight ? Colors.blue[700] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.blue[800] : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper: Build pig type dropdown with inventory display
  Widget _buildPigTypeWithInventory() {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snap) {
        final types = snap.data ?? [];
        
        final PigTypeEntity? selected = types.isEmpty
          ? null
          : types.firstWhere(
            (t) => t.name == _pigTypeController.text,
            orElse: () => types.first,
            );

        return SizedBox(
          height: 48,
          child: DropdownButtonFormField<PigTypeEntity>(
            value: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Loại heo',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            items: types.map((type) {
              return DropdownMenuItem<PigTypeEntity>(
                value: type,
                child: _PigTypeDropdownMenuItem(
                  type: type,
                  invoiceRepo: _invoiceRepo,
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _pigTypeController.text = v.name;
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDeductionField() {
    return SizedBox(
       height: 48,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _deductionController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() => _updateAutoDiscount()),
              decoration: const InputDecoration(
                labelText: 'Trừ hao (kg)',
                labelStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _adjustDeduction(1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.keyboard_arrow_up, size: 16),
                      ),
                    ),
                  ),
                ),
                 const SizedBox(height: 1),
                Expanded(
                  child: InkWell(
                    onTap: () => _adjustDeduction(-1),
                    child: Container(
                       decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            const BorderRadius.vertical(bottom: Radius.circular(4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.keyboard_arrow_down, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityFieldWithButtons() {
    return SizedBox(
       height: 48,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Số lượng',
                labelStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final current = int.tryParse(_quantityController.text) ?? 1;
                      setState(() {
                        _quantityController.text = '${current + 1}';
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.keyboard_arrow_up, size: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final current = int.tryParse(_quantityController.text) ?? 1;
                      if (current > 1) {
                        setState(() {
                          _quantityController.text = '${current - 1}';
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            const BorderRadius.vertical(bottom: Radius.circular(4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.keyboard_arrow_down, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build partner debt display field
  Widget _buildPartnerDebtField() {
    if (_selectedPartner == null) {
      return _buildGridLockedField(
        label: 'Công nợ',
        value: '0 đ',
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculatePartnerDebt(_selectedPartner!.id),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        return _buildGridLockedField(
          label: 'Công nợ',
          value: _currencyFormat.format(remaining),
          highlight: remaining > 0,
        );
      },
    );
  }

  // Helper: Build inventory display field
  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    final requestedQty = int.tryParse(_quantityController.text) ?? 0;

    return RepaintBoundary(
      child: StreamBuilder<int>(
        stream: _invoiceRepo.watchPigTypeInventory(pigType),
        builder: (context, snapshot) {
          final availableQty = snapshot.data ?? 0;
          final isValid = pigType.isEmpty || requestedQty <= availableQty;
          return _buildInventoryContainer(availableQty, isValid);
        },
      ),
    );
  }

  Widget _buildInventoryContainer(int qty, bool isValid) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tồn kho',
            style: TextStyle(
              fontSize: 10,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            '$qty con',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.green[800] : Colors.red[800],
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            elevation: 2,
            child: Center(child: Text('Chưa có phiếu xuất nào trong ngày.')),
          );
        }
        
        var invoices = snapshot.data!;

        // Filter invoices
        invoices = invoices.where((inv) {
          final partner = _searchPartnerController.text.trim().toLowerCase();
          final pigType = _searchPigTypeController.text.trim().toLowerCase();
          final quantity = _searchQuantityController.text.trim();

          final invPartner = (inv.partnerName ?? 'Khách lẻ').toLowerCase();
          final invPigType = inv.details.isNotEmpty
              ? (inv.details.first.pigType ?? '').toLowerCase()
              : '';
          final invQuantity = '${inv.totalQuantity}';

          bool matches = true;
          if (partner.isNotEmpty && !invPartner.contains(partner)) {
            matches = false;
          }
          if (pigType.isNotEmpty && !invPigType.contains(pigType)) {
            matches = false;
          }
          if (quantity.isNotEmpty && !invQuantity.contains(quantity)) {
            matches = false;
          }
          return matches;
        }).toList();

        return Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU XUẤT ĐÃ LƯU (${invoices.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blue),
                    ),
                    const Spacer(),
                    if (_activeSearchColumns.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeSearchColumns.clear();
                            _searchPartnerController.clear();
                            _searchPigTypeController.clear();
                            _searchQuantityController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Xóa lọc',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              // Data table
              Expanded(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      dataRowMaxHeight: 48,
                      headingRowHeight: 36,
                      columns: const [
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Thời gian')),
                        DataColumn(label: Text('Khách hàng')),
                        DataColumn(label: Text('Loại heo')),
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('TL Cân')),
                        DataColumn(label: Text('Trừ hao')),
                        DataColumn(label: Text('TL Thực')),
                        DataColumn(label: Text('Đơn giá')),
                        DataColumn(label: Text('Thành tiền')),
                        DataColumn(label: Text('Chiết khấu')),
                        DataColumn(label: Text('Thực thu')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('')),
                      ],
                      rows: List.generate(invoices.length, (idx) {
                        final inv = invoices[idx];
                        final pigType = inv.details.isNotEmpty
                            ? (inv.details.first.pigType ?? '-')
                            : '-';
                        final isWeighed = inv.totalWeight > 0;

                        return DataRow(
                          color:
                              WidgetStateProperty.resolveWith<Color?>((states) {
                            if (!isWeighed) return Colors.red[50];
                            return null;
                          }),
                          cells: [
                            DataCell(Center(child: Text('${idx + 1}'))),
                            DataCell(Text(
                                DateFormat('dd/MM HH:mm')
                                    .format(inv.createdDate),
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12))),
                            DataCell(SizedBox(
                                width: 120,
                                child: Text(inv.partnerName ?? 'Khách lẻ',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)))),
                            DataCell(Text(pigType,
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text('${inv.totalQuantity}',
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_numberFormat.format(inv.totalWeight)} kg',
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_numberFormat.format(inv.deduction)} kg',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_numberFormat.format(inv.netWeight)} kg',
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    _currencyFormat.format(inv.pricePerKg),
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    _currencyFormat.format(inv.subtotal),
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    _currencyFormat.format(inv.discount),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.red)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    _currencyFormat.format(inv.finalAmount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isWeighed
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isWeighed ? 'Đã cân' : 'Chưa cân',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isWeighed
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  tooltip: 'Xem',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => InvoiceDetailScreen(
                                                invoiceId: inv.id)));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  tooltip: 'Xóa',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xóa phiếu'),
                                        content: const Text(
                                            'Bạn có chắc muốn xóa phiếu này? Hành động này không thể hoàn tác.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('HỦY')),
                                          TextButton(
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text('XÓA')),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await sl<IInvoiceRepository>()
                                          .deleteInvoice(inv.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..removeCurrentSnackBar()
                                          ..showSnackBar(const SnackBar(
                                                content: Text('Đã xóa phiếu.')));
                                      }
                                    }
                                  },
                                ),
                              ],
                            )),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnerSelector(BuildContext context) {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        final PartnerEntity? safeValue;
        if (_selectedPartner != null && partners.any((p) => p.id == _selectedPartner!.id)) {
          safeValue = _selectedPartner;
        } else {
          safeValue = null;
        }

        return SizedBox(
          height: 48,
          child: DropdownButtonFormField<PartnerEntity>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khách hàng',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            value: safeValue,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            items: partners
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedPartner = value);
            },
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: FilledButton.icon(
        onPressed: _canSaveInvoice() ? () => _saveInvoice(context) : null,
        icon: const Icon(Icons.save),
        label: const Text('LƯU (F4)'),
        style: FilledButton.styleFrom(
          backgroundColor: _canSaveInvoice() ? null : Colors.grey,
        ),
      ),
    );
  }

  bool _canSaveInvoice() {
    return _selectedPartner != null &&
        _pigTypeController.text.isNotEmpty &&
        _pricePerKg > 0 &&
        (int.tryParse(_quantityController.text) ?? 0) > 0 &&
        _isWeightLocked &&
        _netWeight > 0;
  }

  void _saveInvoice(BuildContext context) async {
    if (!_canSaveInvoice()) {
      String error = 'Vui lòng điền đủ thông tin.';
       if (_selectedPartner == null) {
        error = 'Vui lòng chọn khách hàng.';
      } else if (_pigTypeController.text.isEmpty) {
        error = 'Vui lòng chọn loại heo.';
      } else if (!_isWeightLocked || _netWeight <= 0) {
        error = 'Vui lòng chốt cân và đảm bảo trọng lượng thực > 0.';
      } else if (_pricePerKg <= 0) {
        error = 'Vui lòng nhập đơn giá.';
      }
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
          SnackBar(
            content: Text('⚠️ $error'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    // --- Start Weighing Process ---
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final pigType = _pigTypeController.text.trim();

    try {
      final available = await _invoiceRepo.watchPigTypeInventory(pigType).first;

      if (quantity > available) {
        if (mounted) {
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
            SnackBar(
              content: Text(
                '❌ Không đủ hàng! Loại: $pigType | Tồn: $available | Yêu cầu: $quantity',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      context.read<WeighingBloc>().add(
            WeighingItemAdded(
              weight: _grossWeight,
              quantity: quantity,
              batchNumber: _batchNumberController.text.isNotEmpty
                  ? _batchNumberController.text
                  : null,
              pigType: pigType,
            ),
          );

      context.read<WeighingBloc>().add(
            WeighingInvoiceUpdated(
              partnerId: _selectedPartner!.id,
              partnerName: _selectedPartner!.name,
              pricePerKg: _pricePerKg,
              deduction: _deduction,
              discount: _discount,
              note: _noteController.text,
            ),
          );
      
      context.read<WeighingBloc>().add(const WeighingSaved());

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== DEBT SECTION ====================

  Widget _buildDebtSection(BuildContext context) {
    final hasPartner = _selectedPartner != null;
    final partnerId = _selectedPartner?.id;
    final partnerName = _selectedPartner?.name ?? 'Chưa chọn khách hàng';

    return Card(
      elevation: 3,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'CÔNG NỢ & THANH TOÁN',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Khách: $partnerName',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: hasPartner ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasPartner && partnerId != null) ...[
                  SizedBox(
                    height: 32,
                    child: FilledButton.icon(
                      onPressed: () => _savePayment(context),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Xác nhận',
                          style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showPartnerDebtDetail(context, partnerId),
                    icon: const Icon(Icons.visibility, size: 16),
                    label:
                        const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const Divider(height: 16),

            // Content
            if (!hasPartner)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng chọn khách hàng để xem công nợ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _buildPartnerDebtContent(partnerId!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerDebtContent(String partnerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculatePartnerDebt(partnerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final debtInfo = snapshot.data ?? {};
        final totalDebt = (debtInfo['totalDebt'] as num?)?.toDouble() ?? 0.0;
        final totalPaid = (debtInfo['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // COL 1: Lịch sử thanh toán & trả nợ
            Expanded(
              flex: 3,
              child: _buildTransactionHistory(partnerId),
            ),
            const VerticalDivider(width: 16),

            // COL 2: Payment forms & Summary
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thanh toán & Trả nợ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Row 1: TT phiếu mới
                  Row(
                    children: [
                      const Text('TT Phiếu:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _buildMiniChip('TM', 0, _selectedPaymentMethod, (v) => setState(() => _selectedPaymentMethod = v), Colors.green),
                      _buildMiniChip('CK', 1, _selectedPaymentMethod, (v) => setState(() => _selectedPaymentMethod = v), Colors.blue),
                      _buildMiniChip('NỢ', 2, _selectedPaymentMethod, (v) {
                        setState(() {
                          _selectedPaymentMethod = v;
                          _invoicePaymentAmountController.text = '0';
                        });
                      }, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 4),
                   SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _invoicePaymentAmountController,
                        keyboardType: TextInputType.number,
                        enabled: _selectedPaymentMethod != 2,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          suffixText: 'đ',
                          filled: _selectedPaymentMethod == 2,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Row 2: Trả nợ
                   Row(
                    children: [
                      const Text('Trả nợ cũ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _buildMiniChip('TM', 0, _selectedDebtPaymentMethod, (v) => setState(() => _selectedDebtPaymentMethod = v), Colors.green),
                      _buildMiniChip('CK', 1, _selectedDebtPaymentMethod, (v) => setState(() => _selectedDebtPaymentMethod = v), Colors.blue),
                    ],
                  ),
                   const SizedBox(height: 4),
                   SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _paymentAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          suffixText: 'đ',
                        ),
                      ),
                    ),
                  const Spacer(),
                  // COL 3: Summary boxes
                  _buildCompactDebtBox('Tổng Mua', totalDebt, Colors.orange),
                  const SizedBox(height: 4),
                  _buildCompactDebtBox('Đã Trả', totalPaid, Colors.green),
                  const SizedBox(height: 4),
                  _buildCompactDebtBox('NỢ CÒN LẠI', remaining, remaining > 0 ? Colors.red : Colors.green, highlight: true),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniChip(String label, int value, int groupValue, Function(int) onSelect, Color color) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? color : Colors.grey[400]!),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.grey[800])),
      ),
    );
  }

  Widget _buildCompactDebtBox(String label, double value, Color color, {bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(highlight ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: highlight ? Border.all(color: color, width: 1.5) : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color is MaterialColor ? color[800] : color, fontWeight: FontWeight.w600)),
          Text(_currencyFormat.format(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color is MaterialColor ? color[900] : color)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(String partnerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch sử giao dịch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: StreamBuilder<List<Transaction>>(
              stream: _db.transactionsDao.watchTransactionsByPartner(partnerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có giao dịch',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  );
                }
                final transactions = snapshot.data!;
                return SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 8,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 36,
                    headingRowHeight: 34,
                    columns: const [
                      DataColumn(label: Text('Ngày', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Loại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Số tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(transactions.length, (idx) {
                      final tx = transactions[idx];
                      final isPayment = tx.type == 0;
                      return DataRow(cells: [
                        DataCell(Text(
                          DateFormat('dd/MM').format(tx.transactionDate),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        )),
                        DataCell(Text(isPayment ? 'TT Phiếu' : 'Trả Nợ',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPayment ? Colors.green[700] : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ))),
                        DataCell(Text(
                          _currencyFormat.format(tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isPayment ? Colors.green[800] : Colors.blue[800],
                          ),
                        )),
                      ]);
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _calculatePartnerDebt(String partnerId) async {
    final invoices = await _invoiceRepo.watchInvoices(type: 2).first;
    final partnerInvoices = invoices.where((inv) => inv.partnerId == partnerId).toList();
    double totalDebt = 0;
    for (final inv in partnerInvoices) {
      totalDebt += inv.finalAmount;
    }

    final transactions = await _db.transactionsDao.watchTransactionsByPartner(partnerId).first;
    double totalPaid = 0;
    for (final tx in transactions) {
      totalPaid += tx.amount;
    }

    return {
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'remaining': (totalDebt - totalPaid).clamp(0, double.infinity),
    };
  }

  void _showPartnerDebtDetail(BuildContext context, String partnerId) async {
    final debtInfo = await _calculatePartnerDebt(partnerId);
    final invoices = await _invoiceRepo.watchInvoices(type: 2).first;
    final partnerInvoices = invoices.where((inv) => inv.partnerId == partnerId).toList();
    final transactions = await _db.transactionsDao.watchTransactionsByPartner(partnerId).first;
    final partner = await _db.partnersDao.getPartnerById(partnerId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Chi tiết công nợ - ${partner?.name ?? ""}'),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('TỔNG MUA',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                _currencyFormat.format(debtInfo['totalDebt']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('ĐÃ TRẢ',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                _currencyFormat.format(debtInfo['totalPaid']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('CÒN LẠI',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                _currencyFormat.format(debtInfo['remaining']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Invoices list
                const Text('Danh sách phiếu mua:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DataTable(
                  columnSpacing: 12,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('TL (kg)')),
                    DataColumn(label: Text('Đơn giá')),
                    DataColumn(label: Text('Thành tiền')),
                  ],
                  rows: partnerInvoices
                      .map((inv) => DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yy')
                                .format(inv.createdDate))),
                            DataCell(
                                Text(_numberFormat.format(inv.totalWeight))),
                            DataCell(
                                Text(_currencyFormat.format(inv.pricePerKg))),
                            DataCell(Text(
                                _currencyFormat.format(inv.finalAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                          ]))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Payments list
                const Text('Lịch sử thanh toán:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                transactions.isEmpty
                    ? const Text('Chưa có thanh toán',
                        style: TextStyle(color: Colors.grey))
                    : DataTable(
                        columnSpacing: 12,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 36,
                        columns: const [
                          DataColumn(label: Text('Ngày')),
                          DataColumn(label: Text('Hình thức')),
                          DataColumn(label: Text('Số tiền')),
                          DataColumn(label: Text('Ghi chú')),
                        ],
                        rows: transactions
                            .map((tx) => DataRow(cells: [
                                  DataCell(Text(DateFormat('dd/MM/yy HH:mm')
                                      .format(tx.transactionDate))),
                                  DataCell(Text(tx.paymentMethod == 0
                                      ? 'Tiền mặt'
                                      : 'Chuyển khoản')),
                                  DataCell(Text(
                                    _currencyFormat.format(tx.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  )),
                                  DataCell(Text(tx.note ?? '-')),
                                ]))
                            .toList(),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePayment(BuildContext context) async {
    if (_selectedPartner == null) {
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
        const SnackBar(
            content: Text('❌ Vui lòng chọn khách hàng'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final partnerId = _selectedPartner!.id;

    final newInvoicePayment = double.tryParse(_invoicePaymentAmountController.text.replaceAll(',', '')) ?? 0;
    final debtRepayment = double.tryParse(_paymentAmountController.text.replaceAll(',', '')) ?? 0;

    if (newInvoicePayment <= 0 && debtRepayment <= 0) {
      // Nothing to save, but maybe the user just saved an invoice as "debt"
      if (_lastSavedInvoice != null && _selectedPaymentMethod == 2) {
         ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
          const SnackBar(
            content: Text('✅ Đã ghi nhận phiếu vào công nợ.'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset only payment fields
        setState(() {
          _lastSavedInvoice = null;
          _invoicePaymentAmountController.clear();
        });
        return;
      }

      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
        const SnackBar(
            content: Text('⚠️ Vui lòng nhập số tiền thanh toán hoặc trả nợ'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final now = DateTime.now();
      
      // Transaction for the new invoice payment
      if (newInvoicePayment > 0 && _selectedPaymentMethod != 2) { // Not "Nợ"
        await _db.transactionsDao.createTransaction(
          TransactionsCompanion(
            id: Value(now.millisecondsSinceEpoch.toString()),
            partnerId: Value(partnerId),
            invoiceId: Value(_lastSavedInvoice?.id), // May be null, that's OK
            amount: Value(newInvoicePayment),
            type: const Value(0), // 0 = Thanh toán
            paymentMethod: Value(_selectedPaymentMethod),
            transactionDate: Value(now),
            note: const Value('Thanh toán phiếu xuất chợ mới'),
          ),
        );
      }

      // Transaction for debt repayment
      if (debtRepayment > 0) {
        await _db.transactionsDao.createTransaction(
          TransactionsCompanion(
            id: Value('${now.millisecondsSinceEpoch}_debt'),
            partnerId: Value(partnerId),
            invoiceId: const Value(null), 
            amount: Value(debtRepayment),
            type: const Value(1), // 1 = Trả nợ
            paymentMethod: Value(_selectedDebtPaymentMethod),
            transactionDate: Value(now),
            note: const Value('Trả nợ cũ'),
          ),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
          const SnackBar(
            content: Text('✅ Đã ghi nhận thanh toán.'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi lưu thanh toán: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // Reset payment fields but keep the partner selected
    setState(() {
      _lastSavedInvoice = null;
      _paymentAmountController.clear();
      _invoicePaymentAmountController.clear();
      _selectedPaymentMethod = 0;
    });
  }
}

class _PigTypeDropdownMenuItem extends StatelessWidget {
  const _PigTypeDropdownMenuItem({
    required this.type,
    required this.invoiceRepo,
  });

  final PigTypeEntity type;
  final IInvoiceRepository invoiceRepo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            type.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        StreamBuilder<int>(
          stream: invoiceRepo.watchPigTypeInventory(type.name),
          builder: (context, inventorySnap) {
            final inv = inventorySnap.data ?? 0;
            return Text(
              ' (Tồn: $inv)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            );
          },
        ),
      ],
    );
  }
}
