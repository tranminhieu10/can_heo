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
  final TextEditingController _quantityController = TextEditingController(text: '1');
  
  // New controllers as per requirements
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmWeightController = TextEditingController();
  final TextEditingController _transportFeeController = TextEditingController(text: '0');
  final TextEditingController _paymentAmountController = TextEditingController();
  
  // Controllers for action row below saved invoices
  final TextEditingController _debtPaymentController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  // Selected invoice for operations
  InvoiceEntity? _selectedInvoice;
  bool _isEditMode = false;
  
  // Resizable panel ratio (0.0 to 1.0, default 0.5 = 50%)
  double _panelRatio = 0.5;
  static const double _minPanelRatio = 0.25;
  static const double _maxPanelRatio = 0.75;

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  PartnerEntity? _selectedPartner;
  final _invoiceRepo = sl<IInvoiceRepository>();

  // Scale data
  double _currentScaleWeight = 0.0;
  double _totalMarketWeight = 0.0; // TL Chợ - from scale
  int _totalQuantity = 0;
  List<Map<String, dynamic>> _currentWeighingList = [];

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
    _farmNameController.dispose();
    _farmWeightController.dispose();
    _transportFeeController.dispose();
    _paymentAmountController.dispose();
    _debtPaymentController.dispose();
    _discountController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _farmWeight => double.tryParse(_farmWeightController.text.replaceAll(',', '')) ?? 0;
  double get _marketWeight => _totalMarketWeight;
  double get _pricePerKg => double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _subtotal => _marketWeight * _pricePerKg; // Thành tiền
  double get _transportFee => double.tryParse(_transportFeeController.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () => _saveInvoice(context),
        const SingleActivator(LogicalKeyboardKey.f2): () => sl<IScaleService>().tare(),
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
            // Update scale weight from state
            if (state.isScaleConnected) {
              setState(() {
                _currentScaleWeight = state.scaleWeight;
              });
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
                  // Row 1: Scale Section | Divider | Invoice Form (resizable)
                  SizedBox(
                    height: 360,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final dividerWidth = 12.0;
                        final availableWidth = totalWidth - dividerWidth;
                        final leftWidth = availableWidth * _panelRatio;
                        final rightWidth = availableWidth * (1 - _panelRatio);
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: Scale Section
                            SizedBox(
                              width: leftWidth,
                              child: _buildScaleSection(context),
                            ),
                            // Draggable Divider
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  final newRatio = _panelRatio + (details.delta.dx / availableWidth);
                                  _panelRatio = newRatio.clamp(_minPanelRatio, _maxPanelRatio);
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: Container(
                                  width: dividerWidth,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Right: Invoice Form
                            SizedBox(
                              width: rightWidth,
                              child: _buildInvoiceDetailsSection(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Row 2: Saved Invoices Grid (full width)
                  Expanded(
                    child: _buildSavedInvoicesGrid(context),
                  ),
                  // Footer
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Phím tắt: [F2] Tare | [F4] Lưu phiếu",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 11),
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

  Widget _buildScaleSection(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final weight = state.scaleWeight;
        final connected = state.isScaleConnected;

        return Card(
          color: Colors.orange[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ROW 1: Scale display - compact
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SỐ CÂN: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        connected ? _numberFormat.format(weight.toInt()) : 'Mất kết nối',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: connected ? Colors.orange[800] : Colors.red,
                        ),
                      ),
                      Text(
                        ' kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ROW 2: Input + Add/Clear buttons - compact
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _scaleInputController,
                          focusNode: _scaleInputFocus,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Nhập TL...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (_) => _addWeighingEntry(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _addWeighingEntry,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Thêm', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _clearAllWeighing,
                          icon: const Icon(Icons.delete_sweep, size: 14),
                          label: const Text('Xóa', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ROW 3: Summary - 3 items in a row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildCompactSummary('SỐ HEO NHẬP', Icons.pets, Colors.orange)),
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
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, snapshot) {
          String value = '0';
          if (snapshot.hasData) {
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
              // Tổng nhập = Thành tiền + Cước xe = (TL Chợ * Đơn giá) + Cước xe
              final subtotal = inv.totalWeight * inv.pricePerKg;
              final transportFee = inv.discount;
              totalAmount += (subtotal + transportFee);
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addWeighingEntry() {
    double weight = 0;
    int quantity = int.tryParse(_quantityController.text) ?? 1;

    if (_scaleInputController.text.isNotEmpty) {
      weight = double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
    } else {
      weight = _currentScaleWeight;
    }

    if (weight > 0) {
      setState(() {
        _currentWeighingList.add({
          'weight': weight,
          'quantity': quantity,
          'timestamp': DateTime.now(),
        });
        _updateTotals();
        _scaleInputController.clear();
      });
    }
  }

  void _clearAllWeighing() {
    setState(() {
      _currentWeighingList.clear();
      _updateTotals();
    });
  }

  void _updateTotals() {
    _totalMarketWeight = 0;
    _totalQuantity = 0;
    for (var entry in _currentWeighingList) {
      _totalMarketWeight += entry['weight'] as double;
      _totalQuantity += entry['quantity'] as int;
    }
  }

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditMode ? '✏️ CHỈNH SỬA PHIẾU NHẬP' : 'THÔNG TIN PHIẾU NHẬP KHO',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isEditMode ? Colors.orange : null,
                    ),
                  ),
                ),
                if (_isEditMode)
                  TextButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo mới', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Form rows - 5 rows as specified
            Expanded(
              child: Column(
                children: [
                  // Row 1: Mã NCC, Tên NCC
                  Expanded(child: _buildFormRow1()),
                  const SizedBox(height: 2),
                  // Row 2: Tên Trại, Số lô
                  Expanded(child: _buildFormRow2()),
                  const SizedBox(height: 2),
                  // Row 3: Loại heo, Tồn kho
                  Expanded(child: _buildFormRow3()),
                  const SizedBox(height: 2),
                  // Row 4: Số lượng, TL Trại, TL Chợ
                  Expanded(child: _buildFormRow4()),
                  const SizedBox(height: 2),
                  // Row 5: Đơn giá, Thành tiền, Thanh toán
                  Expanded(child: _buildFormRow5()),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormRow1() {
    // Row 1: Mã NCC, Tên NCC
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        final safeValue = (partners.contains(_selectedPartner)) ? _selectedPartner : null;

        return Row(
          children: [
            Expanded(
              child: _buildCompactField(
                'Mã NCC',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _selectedPartner?.id ?? '---',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactField(
                'Tên NCC',
                DropdownButtonFormField<PartnerEntity>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  value: safeValue,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  items: partners
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.name, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPartner = value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormRow2() {
    // Row 2: Tên Trại, Số lô
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            'Tên Trại',
            _farmNameController,
            hintText: 'Nhập tên trại',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Số lô',
            _batchNumberController,
            hintText: 'Số lô',
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow3() {
    // Row 3: Loại heo, Tồn kho
    return Row(
      children: [
        Expanded(
          child: _buildPigTypeDropdown(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInventoryDisplayField(),
        ),
      ],
    );
  }

  Widget _buildFormRow4() {
    // Row 4: Số lượng, TL Trại (manual), TL Chợ (from scale)
    return Row(
      children: [
        Expanded(
          child: _buildQuantityFieldWithButtons(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'TL Trại (kg)',
            _farmWeightController,
            hintText: 'TL từ NCC',
            isDecimal: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'TL Chợ (kg)',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                _numberFormat.format(_totalMarketWeight.toInt()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow5() {
    // Row 5: Đơn giá, Thành tiền, Cước xe, Thanh toán
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            'Đơn giá',
            _priceController,
            hintText: 'đ/kg',
            isDecimal: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'Thành tiền',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _currencyFormat.format(_subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Cước xe',
            _transportFeeController,
            hintText: '0',
            isDecimal: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Thanh toán',
            _paymentAmountController,
            hintText: 'Số tiền',
            isDecimal: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildCompactTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    bool isNumber = false,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : isNumber
                    ? TextInputType.number
                    : TextInputType.text,
            inputFormatters: isDecimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : isNumber
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPigTypeDropdown() {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snap) {
        final types = snap.data ?? [];
        final PigTypeEntity? selected = types.isEmpty
            ? null
            : types.firstWhere((t) => t.name == _pigTypeController.text, orElse: () => types.first);

        return _buildCompactField(
          'Loại heo',
          DropdownButtonFormField<PigTypeEntity?>(
            value: selected,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            items: types
                .map((type) => DropdownMenuItem(
                    value: type, child: Text(type.name, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _pigTypeController.text = v.name);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();

    if (pigType.isEmpty) {
      return _buildInventoryContainer(0);
    }

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, importSnap) {
          if (!importSnap.hasData) return _buildInventoryContainer(0);

          return StreamBuilder<List<InvoiceEntity>>(
            stream: _invoiceRepo.watchInvoices(type: 2),
            builder: (context, exportSnap) {
              if (!exportSnap.hasData) return _buildInventoryContainer(0);

              int imported = 0;
              int exported = 0;

              for (final inv in importSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) imported += item.quantity;
                }
              }

              for (final inv in exportSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) exported += item.quantity;
                }
              }

              final availableQty = imported - exported;
              return _buildInventoryContainer(availableQty);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryContainer(int qty) {
    return _buildCompactField(
      'Tồn kho',
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$qty con',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityFieldWithButtons() {
    return _buildCompactField(
      'Số lượng',
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: const Center(child: Icon(Icons.keyboard_arrow_up, size: 12)),
                  ),
                ),
                InkWell(
                  onTap: () {
                    final current = int.tryParse(_quantityController.text) ?? 1;
                    if (current > 1) setState(() => _quantityController.text = '${current - 1}');
                  },
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    ),
                    child: const Center(child: Icon(Icons.keyboard_arrow_down, size: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Làm mới',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final canSave = _canSaveInvoice();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditMode) ...[
            TextButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Hủy'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton.icon(
            onPressed: canSave 
                ? () => _isEditMode ? _updateInvoice(context) : _saveInvoice(context) 
                : null,
            icon: Icon(_isEditMode ? Icons.edit : Icons.save),
            label: Text(_isEditMode ? 'CẬP NHẬT' : 'LƯU (F4)'),
            style: FilledButton.styleFrom(
              backgroundColor: canSave 
                  ? (_isEditMode ? Colors.orange : null) 
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveInvoice() {
    return _selectedPartner != null &&
        _pigTypeController.text.isNotEmpty &&
        _pricePerKg > 0 &&
        _totalMarketWeight > 0;
  }

  void _saveInvoice(BuildContext context) {
    if (!_canSaveInvoice()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng điền đầy đủ thông tin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final pigType = _pigTypeController.text.trim();

    // Add invoice item
    context.read<WeighingBloc>().add(
          WeighingItemAdded(
            weight: _totalMarketWeight,
            quantity: _totalQuantity > 0 ? _totalQuantity : quantity,
            batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
            pigType: pigType,
          ),
        );

    // Update invoice info
    // Note: Store farmName in note, farmWeight in deduction, transportFee in discount
    final note = _farmNameController.text.isNotEmpty
        ? 'Trại: ${_farmNameController.text}${_noteController.text.isNotEmpty ? ' | ${_noteController.text}' : ''}'
        : _noteController.text;

    // Calculate payment amount - use input value or default to full amount
    final paymentAmount = double.tryParse(_paymentAmountController.text.replaceAll(',', '')) ?? _subtotal + _transportFee;

    context.read<WeighingBloc>().add(
          WeighingInvoiceUpdated(
            partnerId: _selectedPartner!.id,
            partnerName: _selectedPartner!.name,
            pricePerKg: _pricePerKg,
            deduction: _farmWeight, // Store farm weight here
            discount: _transportFee, // Store transport fee here
            note: note,
            finalAmount: paymentAmount, // Store payment amount
          ),
        );

    // Save
    context.read<WeighingBloc>().add(const WeighingSaved());
  }

  void _resetForm() {
    _scaleInputController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    _pigTypeController.clear();
    _priceController.clear();
    _quantityController.text = '1';
    _farmNameController.clear();
    _farmWeightController.clear();
    _transportFeeController.text = '0';
    _paymentAmountController.clear();
    setState(() {
      _selectedPartner = null;
      _selectedInvoice = null;
      _isEditMode = false;
      _currentWeighingList.clear();
      _totalMarketWeight = 0;
      _totalQuantity = 0;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(0));
    _scaleInputFocus.requestFocus();
  }

  /// Load invoice data into form for editing
  void _loadInvoiceToForm(InvoiceEntity invoice) {
    // Extract farm name from note
    String farmName = '';
    String otherNote = '';
    if (invoice.note != null && invoice.note!.startsWith('Trại: ')) {
      final parts = invoice.note!.split(' | ');
      if (parts.isNotEmpty) {
        farmName = parts[0].replaceFirst('Trại: ', '');
        if (parts.length > 1) {
          otherNote = parts.sublist(1).join(' | ');
        }
      }
    } else {
      otherNote = invoice.note ?? '';
    }

    final pigType = invoice.details.isNotEmpty ? (invoice.details.first.pigType ?? '') : '';
    final batchNumber = invoice.details.isNotEmpty ? (invoice.details.first.batchNumber ?? '') : '';
    
    // Calculate values
    final farmWeight = invoice.deduction;
    final marketWeight = invoice.totalWeight;
    final transportFee = invoice.discount;
    final paidAmount = invoice.finalAmount;

    debugPrint('=== LOAD INVOICE TO FORM ===');
    debugPrint('Invoice ID: ${invoice.id}');
    debugPrint('Partner: ${invoice.partnerName}');
    debugPrint('MarketWeight (totalWeight): $marketWeight');
    debugPrint('FarmWeight (deduction): $farmWeight');
    debugPrint('TransportFee (discount): $transportFee');
    debugPrint('PricePerKg: ${invoice.pricePerKg}');
    debugPrint('FinalAmount: $paidAmount');
    debugPrint('PigType: $pigType');

    setState(() {
      _selectedInvoice = invoice;
      _isEditMode = true;
      
      // Load partner
      // Find partner by ID from bloc state
      final partnerState = context.read<PartnerBloc>().state;
      _selectedPartner = partnerState.partners.firstWhere(
        (p) => p.id == invoice.partnerId,
        orElse: () => partnerState.partners.isNotEmpty 
            ? partnerState.partners.first 
            : PartnerEntity(id: invoice.partnerId ?? '', name: invoice.partnerName ?? '', isSupplier: true, currentDebt: 0),
      );
      
      // Load form fields
      _farmNameController.text = farmName;
      _noteController.text = otherNote;
      _pigTypeController.text = pigType;
      _batchNumberController.text = batchNumber;
      _quantityController.text = '${invoice.totalQuantity}';
      _farmWeightController.text = farmWeight > 0 ? farmWeight.toStringAsFixed(1) : '';
      _priceController.text = invoice.pricePerKg > 0 ? invoice.pricePerKg.toStringAsFixed(0) : '';
      _transportFeeController.text = transportFee.toStringAsFixed(0);
      _paymentAmountController.text = paidAmount > 0 ? paidAmount.toStringAsFixed(0) : '';
      
      // Load weighing data
      _totalMarketWeight = marketWeight;
      _totalQuantity = invoice.totalQuantity;
      _currentWeighingList = [
        {
          'weight': marketWeight,
          'quantity': invoice.totalQuantity,
          'timestamp': invoice.createdDate,
        }
      ];
    });
  }

  /// Update existing invoice
  Future<void> _updateInvoice(BuildContext context) async {
    if (_selectedInvoice == null) return;
    
    if (!_canSaveInvoice()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng điền đầy đủ thông tin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final pigType = _pigTypeController.text.trim();
      
      // Build note
      final note = _farmNameController.text.isNotEmpty
          ? 'Trại: ${_farmNameController.text}${_noteController.text.isNotEmpty ? ' | ${_noteController.text}' : ''}'
          : _noteController.text;
      
      // Calculate payment amount
      final paymentAmount = double.tryParse(_paymentAmountController.text.replaceAll(',', '')) ?? _subtotal + _transportFee;

      debugPrint('=== UPDATE INVOICE ===');
      debugPrint('Invoice ID: ${_selectedInvoice!.id}');
      debugPrint('Partner: ${_selectedPartner!.name}');
      debugPrint('TotalWeight: $_totalMarketWeight');
      debugPrint('Quantity: ${_totalQuantity > 0 ? _totalQuantity : quantity}');
      debugPrint('PricePerKg: $_pricePerKg');
      debugPrint('Deduction (FarmWeight): $_farmWeight');
      debugPrint('Discount (TransportFee): $_transportFee');
      debugPrint('FinalAmount (Payment): $paymentAmount');
      debugPrint('Note: $note');

      // Get quantity from form - use form value, not _totalQuantity which may be stale
      final formQuantity = int.tryParse(_quantityController.text) ?? 1;
      final finalQuantity = formQuantity > 0 ? formQuantity : quantity;
      
      debugPrint('Form quantity: $formQuantity, Final quantity: $finalQuantity');

      // Create updated invoice
      final updatedInvoice = _selectedInvoice!.copyWith(
        partnerId: _selectedPartner!.id,
        partnerName: _selectedPartner!.name,
        totalWeight: _totalMarketWeight,
        totalQuantity: finalQuantity,
        pricePerKg: _pricePerKg,
        deduction: _farmWeight,
        discount: _transportFee,
        finalAmount: paymentAmount,
        note: note,
      );

      // Update invoice in database
      await _invoiceRepo.updateInvoice(updatedInvoice);
      debugPrint('Invoice updated successfully');
      
      // Update invoice details if needed
      if (_selectedInvoice!.details.isNotEmpty) {
        debugPrint('Updating weighing item: ${_selectedInvoice!.details.first.id}');
        final updatedItem = _selectedInvoice!.details.first.copyWith(
          pigType: pigType,
          batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
          weight: _totalMarketWeight,
          quantity: finalQuantity,
        );
        await _invoiceRepo.updateWeighingItem(updatedItem);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật phiếu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _resetForm();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if deleting an import invoice would cause negative inventory
  Future<bool> _canDeleteImportInvoice(InvoiceEntity invoice) async {
    try {
      final importInvoices = await _invoiceRepo.watchInvoices(type: 0).first;
      final exportInvoices = await _invoiceRepo.watchInvoices(type: 2).first;

      // Get pig types and quantities from this invoice
      Map<String, int> invoicePigTypes = {};
      for (final item in invoice.details) {
        final pigType = (item.pigType ?? '').trim();
        if (pigType.isNotEmpty) {
          invoicePigTypes[pigType] = (invoicePigTypes[pigType] ?? 0) + item.quantity;
        }
      }

      // Calculate current inventory for each pig type
      for (final pigType in invoicePigTypes.keys) {
        int imported = 0;
        int exported = 0;

        for (final inv in importInvoices) {
          // Skip the invoice we're trying to delete
          if (inv.id == invoice.id) continue;
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

        // If deleting this invoice would make inventory negative
        final remainingInventory = imported - exported;
        if (remainingInventory < 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _confirmDeleteImportInvoice(BuildContext context, InvoiceEntity invoice) async {
    // First check if we can delete
    final canDelete = await _canDeleteImportInvoice(invoice);
    
    if (!canDelete) {
      if (context.mounted) {
        // Get pig type info for better error message
        String pigTypes = invoice.details.map((d) => d.pigType ?? 'N/A').toSet().join(', ');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Không thể xóa phiếu! Loại heo "$pigTypes" sẽ bị âm tồn kho nếu xóa phiếu này.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu'),
        content: const Text('Bạn có chắc muốn xóa phiếu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _invoiceRepo.deleteInvoice(invoice.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa phiếu')),
        );
      }
    }
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 0),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var invoices = snapshot.data!;
        if (invoices.isEmpty) return const Center(child: Text('Chưa có phiếu nhập nào'));

        return Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU NHẬP ĐÃ LƯU (${invoices.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              // Data table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                                showCheckboxColumn: false,
                                columnSpacing: 12,
                                horizontalMargin: 10,
                                headingRowHeight: 40,
                                dataRowMinHeight: 36,
                                dataRowMaxHeight: 44,
                                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                dataTextStyle: const TextStyle(fontSize: 12),
                                columns: const [
                                  DataColumn(label: Text('STT')),
                                  DataColumn(label: Text('Thời gian')),
                                  DataColumn(label: Text('Tên NCC')),
                                  DataColumn(label: Text('Tên Trại')),
                                  DataColumn(label: Text('Loại heo')),
                                  DataColumn(label: Text('Số lô')),
                                  DataColumn(label: Text('SL')),
                                  DataColumn(label: Text('TL Trại')),
                                  DataColumn(label: Text('TL Chợ')),
                                  DataColumn(label: Text('Hao hụt')),
                                  DataColumn(label: Text('Đơn giá')),
                                  DataColumn(label: Text('Thành tiền')),
                                  DataColumn(label: Text('Cước xe')),
                                  DataColumn(label: Text('Tổng nhập')),
                                  DataColumn(label: Text('Thanh toán')),
                                  DataColumn(label: Text('Công nợ')),
                                  DataColumn(label: Text('Hình thức')),
                                  DataColumn(label: Text('')),
                                ],
                                rows: List.generate(invoices.length, (idx) {
                                  final inv = invoices[idx];
                                  final dateFormat = DateFormat('dd/MM HH:mm');
                                  
                                  // Check if this is a debt payment or discount invoice (type indicator in note)
                                  final isDebtPayment = inv.note?.contains('[TRẢ NỢ]') ?? false;
                                  final isDiscount = inv.note?.contains('[CHIẾT KHẤU]') ?? false;
                                  final status = isDiscount ? 'Chiết khấu' : (isDebtPayment ? 'Trả nợ' : 'Nhập kho');
                                  
                                  // Extract values - deduction stores farmWeight, discount stores transportFee
                                  final farmWeight = inv.deduction;
                                  final marketWeight = inv.totalWeight;
                                  final wastage = farmWeight - marketWeight;
                                  final transportFee = inv.discount;
                                  
                                  // Calculate based on invoice type
                                  double subtotal;
                                  double totalImport;
                                  double paidAmount;
                                  double remainingDebt;
                                  
                                  if (isDiscount) {
                                    // Chiết khấu: thành tiền = âm, tổng nhập = 0, thanh toán = 0, công nợ = âm
                                    subtotal = inv.finalAmount; // Thành tiền âm
                                    totalImport = 0; // Tổng nhập = 0
                                    paidAmount = 0; // Thanh toán = 0
                                    remainingDebt = inv.finalAmount; // Công nợ = âm
                                  } else {
                                    // For import: subtotal = marketWeight * pricePerKg (not netWeight)
                                    subtotal = marketWeight * inv.pricePerKg;
                                    totalImport = subtotal + transportFee;
                                    // finalAmount stores the paid amount
                                    paidAmount = inv.finalAmount;
                                    remainingDebt = totalImport - paidAmount;
                                  }

                                  // Extract farm name from note
                                  String farmName = '';
                                  if (inv.note != null) {
                                    if (inv.note!.startsWith('Trại: ')) {
                                      final parts = inv.note!.split(' | ');
                                      if (parts.isNotEmpty) {
                                        farmName = parts[0].replaceFirst('Trại: ', '');
                                      }
                                    } else if (inv.note!.contains('[TRẢ NỢ]') || inv.note!.contains('[CHIẾT KHẤU]')) {
                                      // Extract farm name from debt payment/discount note
                                      final match = RegExp(r'Trại: ([^|\[]+)').firstMatch(inv.note!);
                                      if (match != null) {
                                        farmName = match.group(1)?.trim() ?? '';
                                      }
                                    }
                                  }

                                  final pigType = inv.details.isNotEmpty ? (inv.details.first.pigType ?? '-') : '-';
                                  final batchNumber = inv.details.isNotEmpty ? (inv.details.first.batchNumber ?? '-') : '-';

                                  final isSelected = _selectedInvoice?.id == inv.id;

                                  return DataRow(
                                    selected: isSelected,
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.blue.shade100;
                                      }
                                      return null;
                                    }),
                                    onSelectChanged: (selected) {
                                      if (selected == true) {
                                        _loadInvoiceToForm(inv);
                                      } else {
                                        _resetForm();
                                      }
                                    },
                                    cells: [
                                    DataCell(Center(child: Text('${idx + 1}'))),
                                    DataCell(Text(dateFormat.format(inv.createdDate))),
                                    DataCell(SizedBox(
                                      width: 80,
                                      child: Text(inv.partnerName ?? 'NCC', overflow: TextOverflow.ellipsis),
                                    )),
                                    DataCell(SizedBox(
                                      width: 60,
                                      child: Text(farmName, overflow: TextOverflow.ellipsis),
                                    )),
                                    DataCell(Text(pigType)),
                                    DataCell(Text(batchNumber)),
                                    DataCell(Align(alignment: Alignment.centerRight, child: Text('${inv.totalQuantity}'))),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('${_numberFormat.format(farmWeight.toInt())}'),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('${_numberFormat.format(marketWeight.toInt())}'),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${_numberFormat.format(wastage.toInt())}',
                                        style: TextStyle(
                                          color: wastage > 0 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(_currencyFormat.format(inv.pricePerKg)),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(_currencyFormat.format(subtotal)),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(_currencyFormat.format(transportFee)),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _currencyFormat.format(totalImport),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _currencyFormat.format(paidAmount),
                                        style: TextStyle(color: Colors.green[700]),
                                      ),
                                    )),
                                    DataCell(Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _currencyFormat.format(remainingDebt),
                                        style: TextStyle(
                                          color: remainingDebt > 0 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                                    // Status column
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDiscount 
                                              ? Colors.orange.shade100 
                                              : (isDebtPayment ? Colors.purple.shade100 : Colors.blue.shade100),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDiscount 
                                                ? Colors.orange.shade800 
                                                : (isDebtPayment ? Colors.purple : Colors.blue),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 16),
                                          tooltip: 'Xem',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            Navigator.of(context).push(MaterialPageRoute(
                                              builder: (_) => InvoiceDetailScreen(invoiceId: inv.id),
                                            ));
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          tooltip: 'Xóa',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDeleteImportInvoice(context, inv),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }),
                              ),
                  ),
                ),
              ),
              // Action row below the table
              _buildActionRowInside(invoices),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionRowInside(List<InvoiceEntity> invoices) {
    // Calculate totals for summary
    double totalDebt = 0;
    double totalPaid = 0;
    double totalDiscount = 0;
    for (final inv in invoices) {
      final isDiscount = inv.note?.contains('[CHIẾT KHẤU]') ?? false;
      final transportFee = inv.discount;
      final subtotal = inv.subtotal;
      final totalImport = subtotal + transportFee;
      final paidAmount = inv.finalAmount;
      // Tổng công nợ: tổng của tất cả các phiếu
      if (isDiscount) {
        totalDebt += paidAmount; // paidAmount của phiếu chiết khấu là âm
        totalDiscount += paidAmount.abs(); // tổng chiết khấu là trị tuyệt đối
      } else {
        totalDebt += (totalImport - paidAmount);
        totalPaid += paidAmount;
      }
    }

    // Action row below the table
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(top: BorderSide(color: Colors.blue.shade300, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Left section: THAO TÁC + inputs
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // THAO TÁC label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '📝 THAO TÁC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              // Trả nợ
              SizedBox(
                width: 140,
                child: _buildActionTextField('Trả nợ', _debtPaymentController, Colors.green),
              ),
              const SizedBox(width: 12),
              // Chiết khấu
              SizedBox(
                width: 140,
                child: _buildActionTextField('C.Khấu', _discountController, Colors.orange),
              ),
              const SizedBox(width: 12),
              // Xác nhận button
              ElevatedButton.icon(
                onPressed: _selectedInvoice != null ? _applyDebtPayment : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Xác nhận', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right section: Totals
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tổng đã trả
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade400, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tổng đã trả: ', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                    Text(
                      _currencyFormat.format(totalPaid),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tổng công nợ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: totalDebt > 0 ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: totalDebt > 0 ? Colors.red.shade400 : Colors.green.shade400, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tổng công nợ: ',
                      style: TextStyle(fontSize: 12, color: totalDebt > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _currencyFormat.format(totalDebt),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: totalDebt > 0 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tổng chiết khấu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade400, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tổng chiết khấu: ', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500)),
                    Text(
                      _currencyFormat.format(totalDiscount),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTextField(String label, TextEditingController controller, Color color) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(fontSize: 12, color: color.withOpacity(0.5)),
              ),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDebtPayment() async {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn phiếu để thao tác!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final debtPayment = double.tryParse(_debtPaymentController.text) ?? 0;
    final discountPerKg = double.tryParse(_discountController.text) ?? 0;

    if (debtPayment <= 0 && discountPerKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số tiền trả nợ hoặc chiết khấu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Extract farm name from original invoice
      String farmName = '';
      if (_selectedInvoice!.note != null && _selectedInvoice!.note!.startsWith('Trại: ')) {
        final parts = _selectedInvoice!.note!.split(' | ');
        if (parts.isNotEmpty) {
          farmName = parts[0].replaceFirst('Trại: ', '');
        }
      }

      // Create debt payment invoice if debtPayment > 0
      if (debtPayment > 0) {
        final debtInvoiceId = 'debt_${DateTime.now().millisecondsSinceEpoch}';
        final debtNote = '[TRẢ NỢ] Trại: $farmName | Phiếu gốc: ${_selectedInvoice!.id}';
        
        final debtInvoice = InvoiceEntity(
          id: debtInvoiceId,
          partnerId: _selectedInvoice!.partnerId,
          partnerName: _selectedInvoice!.partnerName,
          type: 0, // Import type
          createdDate: DateTime.now(),
          totalWeight: 0,
          totalQuantity: 0,
          pricePerKg: 0,
          deduction: 0,
          discount: 0,
          finalAmount: debtPayment, // Store payment amount in finalAmount (will show in Thành tiền)
          paidAmount: 0,
          note: debtNote,
          details: [],
        );

        await _invoiceRepo.createInvoice(debtInvoice);
      }

      // Create discount invoice if discountPerKg > 0
      // Chiết khấu: nhà CC giảm giá cho kho
      // Hiển thị đầy đủ thông tin phiếu gốc, thành tiền = âm (công nợ trừ đi)
      if (discountPerKg > 0) {
        final discountInvoiceId = 'discount_${DateTime.now().millisecondsSinceEpoch}';
        final discountNote = '[CHIẾT KHẤU] Trại: $farmName | Phiếu gốc: ${_selectedInvoice!.id}';
        
        // Chiết khấu = chiết khấu/kg × số cân gốc (âm để công nợ trừ đi)
        final discountAmount = discountPerKg * _selectedInvoice!.totalWeight;
        
        // Lấy thông tin loại heo từ phiếu gốc
        final pigType = _selectedInvoice!.details.isNotEmpty 
            ? (_selectedInvoice!.details.first.pigType ?? '') 
            : '';
        final batchNumber = _selectedInvoice!.details.isNotEmpty 
            ? (_selectedInvoice!.details.first.batchNumber ?? '') 
            : '';
        
        final discountInvoice = InvoiceEntity(
          id: discountInvoiceId,
          partnerId: _selectedInvoice!.partnerId,
          partnerName: _selectedInvoice!.partnerName,
          type: 0, // Import type
          createdDate: DateTime.now(),
          totalWeight: _selectedInvoice!.totalWeight, // Hiện số cân gốc
          totalQuantity: _selectedInvoice!.totalQuantity, // Hiện số lượng gốc
          pricePerKg: discountPerKg, // Đơn giá = giá chiết khấu/kg
          deduction: _selectedInvoice!.deduction, // Cân trại gốc
          discount: 0, // Cước xe = 0
          finalAmount: -discountAmount, // Thành tiền âm → công nợ âm
          paidAmount: 0,
          note: discountNote,
          details: [],
        );

        await _invoiceRepo.createInvoice(discountInvoice);
        
        // Tạo weighing detail để hiện loại heo
        if (pigType.isNotEmpty) {
          final discountItem = WeighingItemEntity(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
            sequence: 1,
            weight: _selectedInvoice!.totalWeight,
            quantity: _selectedInvoice!.totalQuantity,
            time: DateTime.now(),
            batchNumber: batchNumber.isNotEmpty ? batchNumber : null,
            pigType: pigType,
          );
          await _invoiceRepo.addWeighingItem(discountInvoiceId, discountItem);
        }
      }

      if (mounted) {
        String message = '✅ Đã tạo phiếu: ';
        if (debtPayment > 0) {
          message += 'Trả nợ ${_currencyFormat.format(debtPayment)}';
        }
        if (discountPerKg > 0) {
          if (debtPayment > 0) message += ', ';
          final discountAmount = discountPerKg * _selectedInvoice!.totalWeight;
          message += 'Chiết khấu ${_currencyFormat.format(discountAmount)} (${_currencyFormat.format(discountPerKg)}/kg × ${_selectedInvoice!.totalWeight}kg)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear inputs
      _debtPaymentController.clear();
      _discountController.clear();
      setState(() => _selectedInvoice = null);
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
  }
}
