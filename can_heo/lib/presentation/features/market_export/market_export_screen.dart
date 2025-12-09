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
              _resetForm();
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
                  // ========== PHẦN 1: Scale + Summary | Invoice Form (50/50) ==========
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Scale + Summary (50%)
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Scale Section - scrollable if needed
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildScaleSection(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Summary totals (compact)
                              _buildCompactSummarySection(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right side: Invoice Details Form (50%)
                        Expanded(
                          flex: 1,
                          child: _buildInvoiceDetailsSection(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ========== PHẦN 2: Phiếu xuất đã lưu ==========
                  Expanded(
                    flex: 4,
                    child: _buildSavedInvoicesGrid(context),
                  ),
                  const SizedBox(height: 8),
                  // ========== PHẦN 3: Debt section (always visible) ==========
                  Expanded(
                    flex: 3,
                    child: _buildDebtSection(context),
                  ),
                  // Footer
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Phím tắt: [F1] Chốt cân | [F2] Tare | [F4] Lưu phiếu",
                      style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12),
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

  // Compact summary for left panel
  Widget _buildCompactSummarySection(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 2),
      builder: (context, snapshot) {
        final invoices = snapshot.data ?? [];
        final today = DateTime.now();
        final todayInvoices = invoices.where((inv) {
          return inv.createdDate.year == today.year &&
              inv.createdDate.month == today.month &&
              inv.createdDate.day == today.day;
        }).toList();

        double totalWeight = 0;
        int totalQuantity = 0;
        double totalAmount = 0;

        for (final inv in todayInvoices) {
          totalWeight += inv.totalWeight;
          totalQuantity += inv.totalQuantity;
          totalAmount += inv.finalAmount;
        }

        return Card(
          color: Colors.blue[700],
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactSummaryItem(
                        'Tổng KL',
                        '${_numberFormat.format(totalWeight)} kg',
                        Icons.scale,
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    Expanded(
                      child: _buildCompactSummaryItem(
                        'Số heo',
                        '$totalQuantity',
                        Icons.pets,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        _currencyFormat.format(totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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

  Widget _buildCompactSummaryItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 10),
            const SizedBox(width: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 1),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }

  void _resetForm() {
    _scaleInputController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    _pigTypeController.clear();
    _priceController.clear();
    _quantityController.text = '1';
    _deductionController.text = '0';
    _discountController.text = '0';
    _paymentAmountController.clear();
    setState(() {
      _selectedPartner = null;
      _lockedWeight = 0;
      _isWeightLocked = false;
      _selectedPaymentMethod = 0;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(2));
    _scaleInputFocus.requestFocus();
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
          color: _isWeightLocked ? Colors.green[50] : Colors.blue[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scale display
                Text(
                  _isWeightLocked ? 'ĐÃ CHỐT CÂN' : 'TRỌNG LƯỢNG (kg)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: _isWeightLocked ? Colors.green[700] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isWeightLocked
                      ? _numberFormat.format(_lockedWeight)
                      : (connected
                          ? _numberFormat.format(weight)
                          : 'Mất kết nối'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _isWeightLocked
                        ? Colors.green[800]
                        : (connected ? Colors.blue[800] : Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
                // Manual input - compact
                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _scaleInputController,
                    focusNode: _scaleInputFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (_) => _lockWeightManual(),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Nhập tay (kg)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Buttons - compact
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: connected
                              ? () => sl<IScaleService>().tare()
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('TARE'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: (connected && weight > 0) ||
                                  _scaleInputController.text.isNotEmpty
                              ? () {
                                  if (_scaleInputController.text.isNotEmpty) {
                                    _lockWeightManual();
                                  } else {
                                    _lockWeight(context);
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _isWeightLocked ? Colors.green : null,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: Text(_isWeightLocked ? 'CHỐT ✓' : 'CHỐT'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isWeightLocked)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isWeightLocked = false;
                        _lockedWeight = 0;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Hủy chốt',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  // Unified input field style
  InputDecoration _buildInputDecoration(String label,
      {String? suffix, bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: !enabled,
      fillColor: enabled ? null : Colors.grey[200],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'THÔNG TIN PHIẾU XUẤT CHỢ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isWeightLocked
                            ? Colors.green[100]
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
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isWeightLocked ? 'Đã chốt' : 'Chưa chốt',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isWeightLocked
                                  ? Colors.green[700]
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
                        onPressed: _canAddInvoice()
                            ? () => _addInvoice(context)
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        label:
                            const Text('THÊM', style: TextStyle(fontSize: 12)),
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
            const SizedBox(height: 12),

            // Row 1: Khách hàng | Số lô | Loại heo (+ tồn kho) | Số lượng
            Row(
              children: [
                Expanded(child: _buildPartnerSelector(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridTextField(
                    controller: _batchNumberController,
                    label: 'Số lô',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildPigTypeWithInventory()),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridTextField(
                    controller: _quantityController,
                    label: 'Số lượng',
                    isNumber: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Trừ hao | TL Thực | Đơn giá | Thành tiền
            Row(
              children: [
                Expanded(
                  child: _buildDeductionField(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridLockedField(
                    label: 'TL Thực (kg)',
                    value: _numberFormat.format(_netWeight),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridTextField(
                    controller: _priceController,
                    label: 'Đơn giá (đ)',
                    isNumber: true,
                    onChanged: (_) => setState(() => _updateAutoDiscount()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridLockedField(
                    label: 'Thành tiền',
                    value: _currencyFormat.format(_subtotal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Chiết khấu | Thực thu | Ghi chú (2 cột)
            Row(
              children: [
                Expanded(
                  child: _buildGridTextField(
                    controller: _discountController,
                    label: 'Chiết khấu (đ)',
                    isNumber: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGridLockedField(
                    label: 'THỰC THU',
                    value: _currencyFormat.format(_totalAmount),
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildGridTextField(
                    controller: _noteController,
                    label: 'Ghi chú',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Build uniform text field for grid
  Widget _buildGridTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(
          color: highlight ? Colors.blue : Colors.grey[400]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.blue[700] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.blue[800] : Colors.black87,
            ),
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

        return StreamBuilder<List<InvoiceEntity>>(
          stream: _invoiceRepo.watchInvoices(type: 0),
          builder: (context, importSnap) {
            return StreamBuilder<List<InvoiceEntity>>(
              stream: _invoiceRepo.watchInvoices(type: 2),
              builder: (context, exportSnap) {
                // Calculate inventory for each pig type
                Map<String, int> inventory = {};
                for (final type in types) {
                  final pigType = type.name;
                  final importInvoices = importSnap.data ?? [];
                  final exportInvoices = exportSnap.data ?? [];

                  int imported = 0;
                  int exported = 0;

                  for (final inv in importInvoices) {
                    for (final item in inv.details) {
                      if ((item.pigType ?? '').trim() == pigType) {
                        imported += item.quantity;
                      }
                    }
                  }

                  for (final inv in exportInvoices) {
                    for (final item in inv.details) {
                      if ((item.pigType ?? '').trim() == pigType) {
                        exported += item.quantity;
                      }
                    }
                  }

                  inventory[pigType] = imported - exported;
                }

                return DropdownButtonFormField<PigTypeEntity?>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Loại heo',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: types.map((type) {
                    final inv = inventory[type.name] ?? 0;
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.name} (Tồn: $inv)',
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _pigTypeController.text = v.name;
                      });
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper: Build deduction field with up/down arrows
  Widget _buildDeductionField() {
    return Row(
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _adjustDeduction(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: const Icon(Icons.keyboard_arrow_up, size: 16),
              ),
            ),
            InkWell(
              onTap: () => _adjustDeduction(-1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                child: const Icon(Icons.keyboard_arrow_down, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Locked field that cannot be edited - prevents fraud
  Widget _buildLockedField(String label, String value, Color color,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: highlight ? color : Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
        color: highlight ? color.withOpacity(0.1) : Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 8, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(fontSize: 8, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: highlight ? color : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPigTypeDropdown() {
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
        return DropdownButtonFormField<PigTypeEntity?>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Loại heo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: types
              .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _pigTypeController.text = v.name;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildInventoryBox(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 0),
      builder: (context, importSnap) {
        return StreamBuilder<List<InvoiceEntity>>(
          stream: _invoiceRepo.watchInvoices(type: 2),
          builder: (context, exportSnap) {
            final pigType = _pigTypeController.text.trim();
            int availableQty = 0;

            if (pigType.isNotEmpty) {
              final importInvoices = importSnap.data ?? [];
              final exportInvoices = exportSnap.data ?? [];

              int imported = 0;
              int exported = 0;

              for (final inv in importInvoices) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    imported += item.quantity;
                  }
                }
              }

              for (final inv in exportInvoices) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    exported += item.quantity;
                  }
                }
              }

              availableQty = imported - exported;
            }

            final requestedQty = int.tryParse(_quantityController.text) ?? 0;
            final isValid = pigType.isEmpty || requestedQty <= availableQty;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: isValid ? Colors.green : Colors.red),
                borderRadius: BorderRadius.circular(4),
                color: isValid ? Colors.green[50] : Colors.red[50],
              ),
              child: Column(
                children: [
                  const Text('Tồn',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    '$availableQty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 2),
      builder: (context, snapshot) {
        final invoices = snapshot.data ?? [];

        // Calculate totals from today's invoices
        final today = DateTime.now();
        final todayInvoices = invoices.where((inv) {
          return inv.createdDate.year == today.year &&
              inv.createdDate.month == today.month &&
              inv.createdDate.day == today.day;
        }).toList();

        double totalWeight = 0;
        int totalQuantity = 0;
        double totalAmount = 0;

        for (final inv in todayInvoices) {
          totalWeight += inv.totalWeight;
          totalQuantity += inv.totalQuantity;
          totalAmount += inv.finalAmount;
        }

        return Card(
          color: Colors.blue[800],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('TỔNG KHỐI LƯỢNG',
                    '${_numberFormat.format(totalWeight)} kg', Icons.scale),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildSummaryItem(
                    'TỔNG SỐ HEO', '$totalQuantity con', Icons.pets),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildSummaryItem('TỔNG TIỀN',
                    _currencyFormat.format(totalAmount), Icons.attach_money),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ],
    );
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var invoices = snapshot.data!;
        if (invoices.isEmpty)
          return const Center(child: Text('Chưa có phiếu xuất nào'));

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
          if (partner.isNotEmpty && !invPartner.contains(partner))
            matches = false;
          if (pigType.isNotEmpty && !invPigType.contains(pigType))
            matches = false;
          if (quantity.isNotEmpty && !invQuantity.contains(quantity))
            matches = false;
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
                                            'Bạn có chắc muốn xóa phiếu này?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('HỦY')),
                                          TextButton(
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
                                            .showSnackBar(const SnackBar(
                                                content: Text('Đã xóa phiếu')));
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
        final safeValue =
            (partners.contains(_selectedPartner)) ? _selectedPartner : null;

        return DropdownButtonFormField<PartnerEntity>(
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Khách hàng',
              border: OutlineInputBorder(),
              isDense: true),
          value: safeValue,
          items: partners
              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedPartner = value);
          },
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final canSave = _canSaveInvoice();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: FilledButton.icon(
        onPressed: canSave ? () => _saveInvoice(context) : null,
        icon: const Icon(Icons.save),
        label: const Text('LƯU (F4)'),
        style: FilledButton.styleFrom(
          backgroundColor: canSave ? null : Colors.grey,
        ),
      ),
    );
  }

  bool _canAddInvoice() {
    return _selectedPartner != null &&
        _pigTypeController.text.isNotEmpty &&
        _pricePerKg > 0 &&
        (int.tryParse(_quantityController.text) ?? 0) > 0;
  }

  bool _canSaveInvoice() {
    return _canAddInvoice() && _isWeightLocked && _netWeight > 0;
  }

  void _addInvoice(BuildContext context) async {
    if (!_canAddInvoice()) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final pigType = _pigTypeController.text.trim();

    // Check inventory
    try {
      final importInvoices = await _invoiceRepo.watchInvoices(type: 0).first;
      final exportInvoices = await _invoiceRepo.watchInvoices(type: 2).first;

      int imported = 0;
      int exported = 0;

      for (final inv in importInvoices) {
        for (final item in inv.details) {
          if ((item.pigType ?? '').trim() == pigType) {
            imported += item.quantity;
          }
        }
      }

      for (final inv in exportInvoices) {
        for (final item in inv.details) {
          if ((item.pigType ?? '').trim() == pigType) {
            exported += item.quantity;
          }
        }
      }

      final available = imported - exported;

      if (quantity > available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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

      // Add invoice item - store gross weight (before deduction)
      context.read<WeighingBloc>().add(
            WeighingItemAdded(
              weight: _isWeightLocked ? _grossWeight : 0,
              quantity: quantity,
              batchNumber: _batchNumberController.text.isNotEmpty
                  ? _batchNumberController.text
                  : null,
              pigType: pigType,
            ),
          );

      // Update invoice info with new fields
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

      // Save immediately
      context.read<WeighingBloc>().add(const WeighingSaved());

      // Store info for debt section
      setState(() {
        _lastSavedInvoice = InvoiceEntity(
          id: '',
          type: 2,
          createdDate: DateTime.now(),
          totalWeight: _grossWeight,
          totalQuantity: quantity,
          pricePerKg: _pricePerKg,
          deduction: _deduction,
          discount: _discount,
          finalAmount: _totalAmount,
          partnerId: _selectedPartner!.id,
          partnerName: _selectedPartner!.name,
        );
        _paymentAmountController.text = _totalAmount.toStringAsFixed(0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _saveInvoice(BuildContext context) async {
    if (!_canSaveInvoice()) {
      if (!_isWeightLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng chốt cân trước khi lưu!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _addInvoice(context);
  }

  // ==================== DEBT SECTION ====================

  Widget _buildDebtSection(BuildContext context) {
    // Always show debt section - empty when no partner selected, show data when partner is selected
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
                  'CÔNG NỢ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Text(
                  'Khách: $partnerName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: hasPartner ? Colors.black : Colors.grey,
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

            // Content - Empty placeholder or actual data
            if (!hasPartner)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng chọn khách hàng để xem công nợ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
        final debtInfo = snapshot.data ?? {};
        final totalDebt = debtInfo['totalDebt'] ?? 0.0;
        final totalPaid = debtInfo['totalPaid'] ?? 0.0;
        final remaining = debtInfo['remaining'] ?? 0.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Transaction histories (thanh toán + trả nợ) - chiếm 50% bên trái
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lịch sử thanh toán
                  Expanded(
                      child: _buildTransactionHistory(partnerId,
                          type: 0, title: 'Lịch sử thanh toán')),
                  const SizedBox(width: 8),
                  // Lịch sử trả nợ
                  Expanded(
                      child: _buildTransactionHistory(partnerId,
                          type: 1, title: 'Lịch sử trả nợ')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: Payment forms + Summary boxes - 50% bên phải
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment forms
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payment method for new invoices
                          const Text('Hình thức thanh toán (phiếu mới)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Tiền mặt',
                                    style: TextStyle(fontSize: 10)),
                                selected: _selectedPaymentMethod == 0,
                                onSelected: (selected) {
                                  if (selected)
                                    setState(() => _selectedPaymentMethod = 0);
                                },
                                selectedColor: Colors.green[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Chuyển khoản',
                                    style: TextStyle(fontSize: 10)),
                                selected: _selectedPaymentMethod == 1,
                                onSelected: (selected) {
                                  if (selected)
                                    setState(() => _selectedPaymentMethod = 1);
                                },
                                selectedColor: Colors.blue[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Nợ',
                                    style: TextStyle(fontSize: 10)),
                                selected: _selectedPaymentMethod == 2,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPaymentMethod = 2;
                                      _invoicePaymentAmountController.text =
                                          '0';
                                    });
                                  }
                                },
                                selectedColor: Colors.red[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Invoice payment amount - now below chips
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _invoicePaymentAmountController,
                              keyboardType: TextInputType.number,
                              enabled: _selectedPaymentMethod != 2,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixText: 'đ',
                                suffixStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                filled: _selectedPaymentMethod == 2,
                                fillColor: Colors.grey[200],
                                hintText: 'Số tiền TT phiếu',
                                hintStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Debt repayment method
                          const Text('Hình thức trả nợ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Tiền mặt',
                                    style: TextStyle(fontSize: 10)),
                                selected: _selectedDebtPaymentMethod == 0,
                                onSelected: (selected) {
                                  if (selected)
                                    setState(
                                        () => _selectedDebtPaymentMethod = 0);
                                },
                                selectedColor: Colors.green[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Chuyển khoản',
                                    style: TextStyle(fontSize: 10)),
                                selected: _selectedDebtPaymentMethod == 1,
                                onSelected: (selected) {
                                  if (selected)
                                    setState(
                                        () => _selectedDebtPaymentMethod = 1);
                                },
                                selectedColor: Colors.blue[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Debt payment amount
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _paymentAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixText: 'đ',
                                suffixStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                hintText: 'Số tiền trả nợ',
                                hintStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Summary boxes
                  SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDebtSummaryBox(
                            'Tổng nợ', totalDebt, Colors.orange),
                        const SizedBox(height: 6),
                        _buildDebtSummaryBox('Đã trả', totalPaid, Colors.green),
                        const SizedBox(height: 6),
                        // Remaining - highlight
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: remaining > 0
                                ? Colors.red[100]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                    remaining > 0 ? Colors.red : Colors.green),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'CÒN NỢ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currencyFormat.format(remaining),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0
                                      ? Colors.red[800]
                                      : Colors.green[800],
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
          ],
        );
      },
    );
  }

  Widget _buildDebtSummaryBox(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(String partnerId,
      {int type = 0, String title = 'Lịch sử thanh toán'}) {
    // type 0 = thanh toán, type 1 = trả nợ
    return StreamBuilder<List<Transaction>>(
      stream: _db.transactionsDao.watchTransactionsByPartner(partnerId),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];
        // Filter by transaction type
        final transactions =
            allTransactions.where((tx) => tx.type == type).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          type == 0 ? 'Chưa có thanh toán' : 'Chưa có trả nợ',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      )
                    : SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 12,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 36,
                          headingRowHeight: 34,
                          columns: const [
                            DataColumn(
                                label: Text('STT',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Hình thức',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Số tiền',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Ngày',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: List.generate(transactions.take(10).length,
                              (idx) {
                            final tx = transactions[idx];
                            final paymentMethod = tx.paymentMethod == 0
                                ? 'Tiền mặt'
                                : 'Chuyển khoản';
                            return DataRow(cells: [
                              DataCell(Text('${idx + 1}',
                                  style: const TextStyle(fontSize: 11))),
                              DataCell(Text(paymentMethod,
                                  style: const TextStyle(fontSize: 11))),
                              DataCell(Text(
                                _currencyFormat.format(tx.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: type == 0 ? Colors.green : Colors.blue,
                                ),
                              )),
                              DataCell(Text(
                                DateFormat('dd/MM').format(tx.transactionDate),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              )),
                            ]);
                          }),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculatePartnerDebt(String partnerId) async {
    // Get all invoices for this partner
    final invoices = await _invoiceRepo.watchInvoices(type: 2).first;
    final partnerInvoices =
        invoices.where((inv) => inv.partnerId == partnerId).toList();

    double totalDebt = 0;
    for (final inv in partnerInvoices) {
      totalDebt += inv.finalAmount;
    }

    // Get all payments (transactions) for this partner
    final transactions =
        await _db.transactionsDao.watchTransactionsByPartner(partnerId).first;
    double totalPaid = 0;
    for (final tx in transactions) {
      if (tx.type == 0) {
        // Thu
        totalPaid += tx.amount;
      }
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
    final partnerInvoices =
        invoices.where((inv) => inv.partnerId == partnerId).toList();
    final transactions =
        await _db.transactionsDao.watchTransactionsByPartner(partnerId).first;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Chi tiết công nợ - ${_lastSavedInvoice?.partnerName ?? ""}'),
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
                              const Text('TỔNG NỢ',
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
                const Text('Danh sách phiếu:',
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
    if (_lastSavedInvoice?.partnerId == null && _selectedPartner == null)
      return;

    final partnerId = _lastSavedInvoice?.partnerId ?? _selectedPartner?.id;
    if (partnerId == null) return;

    final amount = double.tryParse(_paymentAmountController.text) ?? 0;

    // If "Nợ" is selected for payment method, we don't create a transaction
    if (_selectedPaymentMethod == 2) {
      // Just reset form, debt is recorded in invoice
      setState(() {
        _lastSavedInvoice = null;
      });
      _resetForm();
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
      // Determine transaction type: 0 = Thanh toán, 1 = Trả nợ
      // If payment method is 0/1 -> create payment transaction
      // Create a transaction record
      await _db.transactionsDao.createTransaction(
        TransactionsCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          partnerId: Value(partnerId),
          invoiceId: const Value(null),
          amount: Value(amount),
          type: const Value(0), // 0 = Thanh toán
          paymentMethod: Value(_selectedPaymentMethod),
          transactionDate: Value(DateTime.now()),
          note: Value('Thanh toán phiếu xuất chợ'),
        ),
      );

      // Also create debt repayment record if debt payment method is selected
      if (_selectedDebtPaymentMethod == 0 || _selectedDebtPaymentMethod == 1) {
        await _db.transactionsDao.createTransaction(
          TransactionsCompanion(
            id: Value('${DateTime.now().millisecondsSinceEpoch}_debt'),
            partnerId: Value(partnerId),
            invoiceId: const Value(null),
            amount: Value(amount),
            type: const Value(1), // 1 = Trả nợ
            paymentMethod: Value(_selectedDebtPaymentMethod),
            transactionDate: Value(DateTime.now()),
            note: Value(
                'Trả nợ - ${_selectedDebtPaymentMethod == 0 ? "Tiền mặt" : "Chuyển khoản"}'),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã ghi nhận: ${_currencyFormat.format(amount)}'),
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

    // Chỉ reset các ô nhập tiền, giữ nguyên khách hàng đang chọn
    setState(() {
      _lastSavedInvoice = null;
      _paymentAmountController.clear();
      _invoicePaymentAmountController.clear();
    });
  }
}
