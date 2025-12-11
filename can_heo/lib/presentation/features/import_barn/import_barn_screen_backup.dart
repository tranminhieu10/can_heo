import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/scale_service.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';
import '../pig_types/pig_types_screen.dart';
import '../history/invoice_detail_screen.dart';

class ImportBarnScreen extends StatelessWidget {
  const ImportBarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeighingBloc>(
          create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(0)),
        ),
        BlocProvider<PartnerBloc>(
          create: (_) => sl<PartnerBloc>()..add(const LoadPartners(true)),
        ),
      ],
      child: const _ImportBarnView(),
    );
  }
}

class _ImportBarnView extends StatefulWidget {
  const _ImportBarnView();

  @override
  State<_ImportBarnView> createState() => _ImportBarnViewState();
}

class _ImportBarnViewState extends State<_ImportBarnView> {
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

  // Track which search columns are visible
  final Set<String> _activeSearchColumns = {};

  // Current weight from scale (locked when user confirms)
  double _lockedWeight = 0;
  bool _isWeightLocked = false;

  // Resizable divider positions
  double _leftPanelFlex = 1.0;

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
                  content: Text('✅ Đã lưu phiếu nhập kho!'),
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
              title: const Text('Phiếu Nhập Kho'),
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
                  // ========== PHẦN 1: Scale + Summary | Invoice Form (Resizable) ==========
                  SizedBox(
                    height: 360,
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
                                    width: 2, color: Colors.grey[400]),
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
                  const SizedBox(height: 8),
                  // ========== PHẦN 2: Phiếu nhập đã lưu ==========
                  Expanded(
                    child: _buildSavedInvoicesGrid(context),
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

  void _resetForm() {
    _scaleInputController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    _pigTypeController.clear();
    _priceController.clear();
    _quantityController.text = '1';
    _deductionController.text = '0';
    _discountController.text = '0';
    setState(() {
      _selectedPartner = null;
      _lockedWeight = 0;
      _isWeightLocked = false;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(0));
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

  Widget _buildScaleSection(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final weight = state.scaleWeight;
        final connected = state.isScaleConnected;

        return Card(
          color: _isWeightLocked ? Colors.green[50] : Colors.orange[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ROW 1: Scale display
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isWeightLocked ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isWeightLocked ? 'ĐÃ CHỐT CÂN' : 'SỐ CÂN (kg)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _isWeightLocked
                                ? Colors.green[700]
                                : Colors.grey,
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
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _isWeightLocked
                                ? Colors.green[800]
                                : (connected ? Colors.orange[800] : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ROW 2: TARE and Lock buttons
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: connected
                                ? () => sl<IScaleService>().tare()
                                : null,
                            style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: const Text('TARE',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
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
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  _isWeightLocked ? Colors.green : null,
                            ),
                            child: Text(
                              _isWeightLocked ? 'HỦY CHỐT' : 'CHỐT CÂN',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ROW 3-5: Summary rows
                  _buildScaleSummaryRow(
                      'TỔNG SỐ HEO NHẬP', Icons.pets, Colors.orange),
                  const SizedBox(height: 8),
                  _buildScaleSummaryRow(
                      'TỔNG KHỐI LƯỢNG', Icons.scale, Colors.blue),
                  const SizedBox(height: 8),
                  _buildScaleSummaryRow(
                      'TỔNG TIỀN', Icons.attach_money, Colors.green),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleSummaryRow(String label, IconData icon, Color color) {
    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildSummaryRowContent(label, icon, color, '0');
          }

          final invoices = snapshot.data!;
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

          String value;
          if (label.contains('SỐ HEO')) {
            value = '$totalQuantity con';
          } else if (label.contains('KHỐI LƯỢNG')) {
            value = '${_numberFormat.format(totalWeight)} kg';
          } else {
            value = _currencyFormat.format(totalAmount);
          }

          return _buildSummaryRowContent(label, icon, color, value);
        },
      ),
    );
  }

  Widget _buildSummaryRowContent(
      String label, IconData icon, Color color, String value) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'THÔNG TIN PHIẾU NHẬP KHO',
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
                      SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: _canAddInvoice()
                              ? () => _addInvoice(context)
                              : null,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('THÊM',
                              style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ROW 1: Mã NCC | Tên NCC
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: TextEditingController(
                            text: _selectedPartner?.id ?? ''),
                        label: 'Mã NCC',
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildPartnerSelector(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 2: Loại heo | Số lô | Tồn kho
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 1, child: _buildPigTypeDropdown()),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                          controller: _batchNumberController, label: 'Số lô'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 1, child: _buildInventoryDisplayField()),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 3: Số lượng | Trọng lượng | Trừ hao | TL Thực
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 1, child: _buildQuantityFieldWithButtons()),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                          label: 'Trọng lượng (kg)',
                          value: _numberFormat.format(_grossWeight)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 1, child: _buildDeductionField()),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                          label: 'TL Thực (kg)',
                          value: _numberFormat.format(_netWeight)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 4: Đơn giá | Thành tiền | Chiết khấu | Thực thu
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: _priceController,
                        label: 'Đơn giá (đ)',
                        isNumber: true,
                        onChanged: (_) => setState(() => _updateAutoDiscount()),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                          label: 'Thành tiền',
                          value: _currencyFormat.format(_subtotal)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: _discountController,
                        label: 'Chiết khấu (đ)',
                        isNumber: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                          label: 'THỰC CHI',
                          value: _currencyFormat.format(_totalAmount),
                          highlight: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 5: Ghi chú
              _buildGridTextField(
                  controller: _noteController, label: 'Ghi chú'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        border: const OutlineInputBorder(),
        isDense: true,
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  Widget _buildGridLockedField(
      {required String label, required String value, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange[50] : Colors.grey[100],
        border:
            Border.all(color: highlight ? Colors.orange : Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: highlight ? Colors.orange[700] : Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: highlight ? Colors.orange[800] : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
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
            labelText: 'Nhà cung cấp',
            labelStyle: TextStyle(fontSize: 10),
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          value: safeValue,
          style: const TextStyle(fontSize: 13, color: Colors.black),
          items: partners
              .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.name, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (value) => setState(() => _selectedPartner = value),
        );
      },
    );
  }

  Widget _buildPigTypeDropdown() {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snap) {
        final types = snap.data ?? [];
        final PigTypeEntity? selected = types.isEmpty
            ? null
            : types.firstWhere((t) => t.name == _pigTypeController.text,
                orElse: () => types.first);

        return DropdownButtonFormField<PigTypeEntity?>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Loại heo',
            labelStyle: TextStyle(fontSize: 10),
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          items: types
              .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _pigTypeController.text = v.name);
          },
        );
      },
    );
  }

  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();

    if (pigType.isEmpty) {
      return _buildInventoryContainer(0, true);
    }

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, importSnap) {
          if (!importSnap.hasData) return _buildInventoryContainer(0, true);

          return StreamBuilder<List<InvoiceEntity>>(
            stream: _invoiceRepo.watchInvoices(type: 2),
            builder: (context, exportSnap) {
              if (!exportSnap.hasData) return _buildInventoryContainer(0, true);

              int imported = 0;
              int exported = 0;

              for (final inv in importSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType)
                    imported += item.quantity;
                }
              }

              for (final inv in exportSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType)
                    exported += item.quantity;
                }
              }

              final availableQty = imported - exported;
              return _buildInventoryContainer(availableQty, true);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryContainer(int qty, bool isValid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tồn kho',
              style: TextStyle(fontSize: 10, color: Colors.green[700]),
              maxLines: 1),
          const SizedBox(height: 2),
          Text('$qty con',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700]),
              maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildQuantityFieldWithButtons() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Số lượng',
              labelStyle: TextStyle(fontSize: 10),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  final current = int.tryParse(_quantityController.text) ?? 1;
                  setState(() => _quantityController.text = '${current + 1}');
                },
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3))),
                  child: const Center(
                      child: Icon(Icons.keyboard_arrow_up, size: 12)),
                ),
              ),
              InkWell(
                onTap: () {
                  final current = int.tryParse(_quantityController.text) ?? 1;
                  if (current > 1)
                    setState(() => _quantityController.text = '${current - 1}');
                },
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3))),
                  child: const Center(
                      child: Icon(Icons.keyboard_arrow_down, size: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _deductionController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() => _updateAutoDiscount()),
            decoration: const InputDecoration(
              labelText: 'Trừ hao (kg)',
              labelStyle: TextStyle(fontSize: 10),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _adjustDeduction(1),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3))),
                  child: const Center(
                      child: Icon(Icons.keyboard_arrow_up, size: 12)),
                ),
              ),
              InkWell(
                onTap: () => _adjustDeduction(-1),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3))),
                  child: const Center(
                      child: Icon(Icons.keyboard_arrow_down, size: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 0),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: Text('Đang tải...'));
        var invoices = snapshot.data!;
        if (invoices.isEmpty)
          return const Center(child: Text('Chưa có phiếu nhập nào'));

        // Filter invoices
        invoices = invoices.where((inv) {
          final partner = _searchPartnerController.text.trim().toLowerCase();
          final pigType = _searchPigTypeController.text.trim().toLowerCase();
          final quantity = _searchQuantityController.text.trim();

          final invPartner = (inv.partnerName ?? 'Nhà cung cấp').toLowerCase();
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU NHẬP ĐÃ LƯU (${invoices.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange),
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
                        DataColumn(label: Text('Nhà cung cấp')),
                        DataColumn(label: Text('Loại heo')),
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('TL Cân')),
                        DataColumn(label: Text('Trừ hao')),
                        DataColumn(label: Text('TL Thực')),
                        DataColumn(label: Text('Đơn giá')),
                        DataColumn(label: Text('Thành tiền')),
                        DataColumn(label: Text('Chiết khấu')),
                        DataColumn(label: Text('Thực chi')),
                        DataColumn(label: Text('')),
                      ],
                      rows: List.generate(invoices.length, (idx) {
                        final inv = invoices[idx];
                        final pigType = inv.details.isNotEmpty
                            ? (inv.details.first.pigType ?? '-')
                            : '-';

                        return DataRow(cells: [
                          DataCell(Center(child: Text('${idx + 1}'))),
                          DataCell(Text(
                              DateFormat('dd/MM HH:mm').format(inv.createdDate),
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12))),
                          DataCell(SizedBox(
                              width: 120,
                              child: Text(inv.partnerName ?? 'NCC',
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
                              child: Text(_currencyFormat.format(inv.subtotal),
                                  style: const TextStyle(fontSize: 13)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(_currencyFormat.format(inv.discount),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.red)))),
                          DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                  _currencyFormat.format(inv.finalAmount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                tooltip: 'Xem',
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
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
                                    await _invoiceRepo.deleteInvoice(inv.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Đã xóa phiếu')));
                                    }
                                  }
                                },
                              ),
                            ],
                          )),
                        ]);
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

  Widget _buildSaveButton(BuildContext context) {
    final canSave = _canSaveInvoice();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: FilledButton.icon(
        onPressed: canSave ? () => _saveInvoice(context) : null,
        icon: const Icon(Icons.save),
        label: const Text('LƯU (F4)'),
        style: FilledButton.styleFrom(
            backgroundColor: canSave ? null : Colors.grey),
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

  void _addInvoice(BuildContext context) {
    if (!_canAddInvoice()) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final pigType = _pigTypeController.text.trim();

    // Add invoice item
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

    // Update invoice info
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
  }

  void _saveInvoice(BuildContext context) {
    if (!_canSaveInvoice()) {
      if (!_isWeightLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('⚠️ Vui lòng chốt cân trước khi lưu!'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    _addInvoice(context);
  }
}
