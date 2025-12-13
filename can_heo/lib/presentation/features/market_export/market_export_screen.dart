import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:async';
import 'package:intl/intl.dart';

import '../../../core/services/scale_service.dart';
import '../../../core/utils/responsive.dart';
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

  // Resizable panel ratio (0.0 to 1.0, default 0.5 = 50%)
  double _panelRatio = 0.5;
  static const double _minPanelRatio = 0.25;
  static const double _maxPanelRatio = 0.75;

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
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Initialize responsive values
                Responsive.init(context);
                
                // Adaptive heights based on screen size
                final topSectionHeight = Responsive.screenType == ScreenType.desktop27 
                    ? 400.0 
                    : Responsive.screenType == ScreenType.desktop24 
                        ? 380.0 
                        : Responsive.screenType == ScreenType.laptop15 
                            ? 360.0 
                            : 340.0;
                final debtBarHeight = Responsive.screenType == ScreenType.desktop27 ? 48.0 : 44.0;
                final padding = Responsive.spacing;

                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    children: [
                      // ========== PHẦN 1: Scale + Summary | Invoice Form (Resizable - Fixed Height) ==========
                      SizedBox(
                        height: topSectionHeight,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final totalWidth = constraints.maxWidth;
                            const dividerWidth = 12.0;
                            final availableWidth = totalWidth - dividerWidth;
                            final leftWidth = availableWidth * _panelRatio;
                            final rightWidth = availableWidth * (1 - _panelRatio);

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left side: Scale + Summary
                                SizedBox(
                                  width: leftWidth,
                                  child: _buildScaleSection(context),
                                ),
                                // Draggable Divider
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      final newRatio = _panelRatio +
                                          (details.delta.dx / availableWidth);
                                      _panelRatio = newRatio.clamp(
                                          _minPanelRatio, _maxPanelRatio);
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
                                // Right side: Invoice Details Form
                                SizedBox(
                                  width: rightWidth,
                                  child: _buildInvoiceDetailsSection(context),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // ========== PHẦN 2: Phiếu xuất đã lưu ==========
                      Expanded(
                        child: _buildSavedInvoicesGrid(context),
                      ),
                      // ========== PHẦN 3: Debt section (always visible) ==========
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
                      color: _isWeightLocked ? Colors.green : Colors.blue,
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
                          fontSize: 14,
                          color: _isWeightLocked
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                      ),
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
                      Text(
                        ' kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isWeightLocked
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ROW 2: Manual input + TARE and Lock buttons - compact
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      // Ô nhập số cân thủ công
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _scaleInputController,
                          focusNode: _scaleInputFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Nhập TL thủ công...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          style: const TextStyle(fontSize: 12),
                          onSubmitted: (_) => _lockWeightManual(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: connected
                              ? () => sl<IScaleService>().tare()
                              : null,
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          child: const Text('TARE',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: (connected && weight > 0) ||
                                  _scaleInputController.text.isNotEmpty
                              ? () {
                                  if (_isWeightLocked) {
                                    setState(() {
                                      _isWeightLocked = false;
                                      _lockedWeight = 0;
                                    });
                                  } else if (_scaleInputController
                                      .text.isNotEmpty) {
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
                            _isWeightLocked ? 'HỦY CHỐT' : 'CHỐT CÂN (F1)',
                            style: const TextStyle(fontSize: 11),
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
                      Expanded(
                          child: _buildCompactSummary(
                              'SỐ HEO BÁN', Icons.pets, Colors.orange)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: _buildCompactSummary(
                              'KHỐI LƯỢNG', Icons.scale, Colors.blue)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: _buildCompactSummary(
                              'TỔNG TIỀN', Icons.attach_money, Colors.green)),
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
        stream: _invoiceRepo.watchInvoices(type: 2),
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
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScaleSummaryRow(String label, IconData icon, Color color) {
    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 2),
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                    'THÔNG TIN PHIẾU XUẤT CHỢ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        _isWeightLocked ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWeightLocked ? Icons.check_circle : Icons.warning,
                        size: 12,
                        color: _isWeightLocked
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _isWeightLocked ? 'Đã chốt' : 'Chưa chốt',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isWeightLocked
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Form rows - 5 rows as specified
            Expanded(
              child: Column(
                children: [
                  // Row 1: Mã KH, Tên KH, Công nợ
                  Expanded(child: _buildFormRow1()),
                  const SizedBox(height: 2),
                  // Row 2: Loại heo, Số lô, Tồn kho
                  Expanded(child: _buildFormRow2()),
                  const SizedBox(height: 2),
                  // Row 3: Số lượng, Trọng lượng, Trừ hao, TL Thực
                  Expanded(child: _buildFormRow3()),
                  const SizedBox(height: 2),
                  // Row 4: Đơn giá, Thành tiền, Chiết khấu, Thực thu
                  Expanded(child: _buildFormRow4()),
                  const SizedBox(height: 2),
                  // Row 5: Ghi chú
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
    // Row 1: Mã KH, Tên KH, Công nợ
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        final safeValue =
            (partners.contains(_selectedPartner)) ? _selectedPartner : null;

        return Row(
          children: [
            Expanded(
              child: _buildCompactField(
                'Mã KH',
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildCompactField(
                'Tên KH',
                DropdownButtonFormField<PartnerEntity>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  value: safeValue,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  items: partners
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedPartner = value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPartnerDebtFieldCompact(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormRow2() {
    // Row 2: Loại heo, Số lô, Tồn kho
    return Row(
      children: [
        Expanded(
          child: _buildPigTypeDropdownCompact(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Số lô',
            _batchNumberController,
            hintText: 'Số lô',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInventoryDisplayFieldCompact(),
        ),
      ],
    );
  }

  Widget _buildFormRow3() {
    // Row 3: Số lượng, Trọng lượng, Trừ hao, TL Thực
    return Row(
      children: [
        Expanded(
          child: _buildQuantityFieldWithButtonsCompact(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'Trọng lượng (kg)',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                _numberFormat.format(_grossWeight),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDeductionFieldCompact(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'TL Thực (kg)',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                _numberFormat.format(_netWeight),
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

  Widget _buildFormRow4() {
    // Row 4: Đơn giá, Thành tiền, Chiết khấu, Thực thu
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            'Đơn giá',
            _priceController,
            hintText: 'đ/kg',
            isDecimal: true,
            onChanged: (_) => _updateAutoDiscount(),
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
            'Chiết khấu',
            _discountController,
            hintText: '0',
            isDecimal: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'THỰC THU',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade500, width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _currencyFormat.format(_totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow5() {
    // Row 5: Ghi chú
    return _buildCompactTextField(
      'Ghi chú',
      _noteController,
      hintText: 'Nhập ghi chú...',
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
    void Function(String)? onChanged,
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
            onChanged: onChanged ?? (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
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

  Widget _buildPartnerDebtFieldCompact() {
    if (_selectedPartner == null) {
      return _buildCompactField(
        'Công nợ',
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Text('0 đ', style: TextStyle(fontSize: 14)),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculatePartnerDebt(_selectedPartner!.id),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        return _buildCompactField(
          'Công nợ',
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: remaining > 0 ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color:
                    remaining > 0 ? Colors.red.shade300 : Colors.green.shade300,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _currencyFormat.format(remaining),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: remaining > 0
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPigTypeDropdownCompact() {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snap) {
        final types = snap.data ?? [];
        final PigTypeEntity? selected = types.isEmpty
            ? null
            : types.firstWhere((t) => t.name == _pigTypeController.text,
                orElse: () => types.first);

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
                    value: type,
                    child:
                        Text(type.name, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _pigTypeController.text = v.name);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryDisplayFieldCompact() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainerCompact(0, true);
    }

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, importSnap) {
          if (!importSnap.hasData) {
            return _buildInventoryContainerCompact(0, true);
          }

          return StreamBuilder<List<InvoiceEntity>>(
            stream: _invoiceRepo.watchInvoices(type: 2),
            builder: (context, exportSnap) {
              if (!exportSnap.hasData) {
                return _buildInventoryContainerCompact(0, true);
              }

              int imported = 0;
              int exported = 0;

              for (final inv in importSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    imported += item.quantity;
                  }
                }
              }

              for (final inv in exportSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    exported += item.quantity;
                  }
                }
              }

              final availableQty = imported - exported;
              final requestedQty = int.tryParse(_quantityController.text) ?? 0;
              final isValid = requestedQty <= availableQty;

              return _buildInventoryContainerCompact(availableQty, isValid);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryContainerCompact(int qty, bool isValid) {
    return _buildCompactField(
      'Tồn kho',
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isValid ? Colors.green[50] : Colors.red[50],
          border: Border.all(color: isValid ? Colors.green : Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$qty con',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isValid ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityFieldWithButtonsCompact() {
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: const Center(
                        child: Icon(Icons.keyboard_arrow_up, size: 12)),
                  ),
                ),
                InkWell(
                  onTap: () {
                    final current = int.tryParse(_quantityController.text) ?? 1;
                    if (current > 1)
                      setState(
                          () => _quantityController.text = '${current - 1}');
                  },
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3)),
                    ),
                    child: const Center(
                        child: Icon(Icons.keyboard_arrow_down, size: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionFieldCompact() {
    return _buildCompactField(
      'Trừ hao (kg)',
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _deductionController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() => _updateAutoDiscount()),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: const Center(
                        child: Icon(Icons.keyboard_arrow_up, size: 12)),
                  ),
                ),
                InkWell(
                  onTap: () => _adjustDeduction(-1),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3)),
                    ),
                    child: const Center(
                        child: Icon(Icons.keyboard_arrow_down, size: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // Helper: Build locked field for grid (readonly)
  Widget _buildGridLockedField({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(
          color: highlight ? Colors.blue : Colors.grey[400]!,
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
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.blue[700] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
                    labelStyle: TextStyle(fontSize: 10),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: types.map((type) {
                    final inv = inventory[type.name] ?? 0;
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.name} (Tồn: $inv)',
                          style: const TextStyle(fontSize: 13)),
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
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_up, size: 12),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _adjustDeduction(-1),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_down, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  setState(() {
                    _quantityController.text = '${current + 1}';
                  });
                },
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_up, size: 12),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  final current = int.tryParse(_quantityController.text) ?? 1;
                  if (current > 1) {
                    setState(() {
                      _quantityController.text = '${current - 1}';
                    });
                  }
                },
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_down, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

    if (pigType.isEmpty) {
      return _buildInventoryContainer(0, true);
    }

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: _invoiceRepo.watchInvoices(type: 0),
        builder: (context, importSnap) {
          if (!importSnap.hasData) {
            return _buildInventoryContainer(0, true);
          }

          return StreamBuilder<List<InvoiceEntity>>(
            stream: _invoiceRepo.watchInvoices(type: 2),
            builder: (context, exportSnap) {
              if (!exportSnap.hasData) {
                return _buildInventoryContainer(0, true);
              }

              int imported = 0;
              int exported = 0;

              for (final inv in importSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    imported += item.quantity;
                  }
                }
              }

              for (final inv in exportSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    exported += item.quantity;
                  }
                }
              }

              final availableQty = imported - exported;
              final requestedQty = int.tryParse(_quantityController.text) ?? 0;
              final isValid = requestedQty <= availableQty;

              return _buildInventoryContainer(availableQty, isValid);
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
        ],
      ),
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
        return DropdownButtonFormField<PigTypeEntity>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Loại heo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: types
              .map((t) => DropdownMenuItem<PigTypeEntity>(
                  value: t, child: Text(t.name)))
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
              SizedBox(
                height: 260,
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
    // Kiểm tra có weight sẵn sàng (đã chốt hoặc đang nhập trong ô)
    double pendingWeight = 0;
    if (_scaleInputController.text.isNotEmpty) {
      pendingWeight =
          double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
    }

    final hasWeight = (_isWeightLocked && _netWeight > 0) || pendingWeight > 0;
    return _canAddInvoice() && hasWeight;
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
    // Tự động chốt cân nếu có số trong ô nhập thủ công
    if (!_isWeightLocked && _scaleInputController.text.isNotEmpty) {
      final manualWeight =
          double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
      if (manualWeight > 0) {
        setState(() {
          _lockedWeight = manualWeight;
          _isWeightLocked = true;
          _scaleInputController.clear();
          _updateAutoDiscount();
        });
      }
    }

    if (!_canSaveInvoice()) {
      if (!_isWeightLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('⚠️ Vui lòng nhập số cân hoặc chốt cân trước khi lưu!'),
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
    final hasPartner = _selectedPartner != null;
    final partnerId = _selectedPartner?.id;
    final partnerName = _selectedPartner?.name ?? 'Chưa chọn khách hàng';

    return FutureBuilder<Map<String, dynamic>>(
      future: hasPartner ? _calculatePartnerDebt(partnerId!) : Future.value({}),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final totalDebt = (debtInfo['totalDebt'] as num?)?.toDouble() ?? 0.0;
        final totalPaid = (debtInfo['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        // Only action bar - no history table
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
                top: BorderSide(color: Colors.orange.shade300, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // CÔNG NỢ label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
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
              // Khách hàng
              Text(
                partnerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: hasPartner ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              // Hình thức thanh toán
              if (hasPartner) ...[
                _buildPaymentChip('T.Mặt', 0, Colors.green),
                const SizedBox(width: 2),
                _buildPaymentChip('C.Khoản', 1, Colors.blue),
                const SizedBox(width: 2),
                _buildPaymentChip('Nợ', 2, Colors.red),
                const SizedBox(width: 2),
                _buildPaymentChip('Trả nợ', 3, Colors.purple),
                const SizedBox(width: 8),
                // Số tiền input
                SizedBox(
                  width: 100,
                  height: 28,
                  child: TextField(
                    controller: _selectedPaymentMethod == 3
                        ? _paymentAmountController
                        : _invoicePaymentAmountController,
                    keyboardType: TextInputType.number,
                    enabled: _selectedPaymentMethod != 2,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      suffixText: 'đ',
                      suffixStyle: const TextStyle(fontSize: 9),
                      filled: _selectedPaymentMethod == 2,
                      fillColor: Colors.grey[200],
                      hintText:
                          _selectedPaymentMethod == 3 ? 'Trả nợ' : 'Số tiền',
                      hintStyle: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Xác nhận button
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: () => _savePayment(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child:
                        const Text('Xác nhận', style: TextStyle(fontSize: 9)),
                  ),
                ),
              ],
              const Spacer(),
              // Totals
              _buildDebtSummaryChip('Tổng nợ', totalDebt, Colors.orange),
              const SizedBox(width: 4),
              _buildDebtSummaryChip('Đã trả', totalPaid, Colors.green),
              const SizedBox(width: 4),
              _buildDebtSummaryChip('Còn nợ', remaining,
                  remaining > 0 ? Colors.red : Colors.green),
              const SizedBox(width: 4),
              // Nút xem lịch sử
              if (hasPartner)
                IconButton(
                  onPressed: () => _showPaymentHistoryDialog(
                      context, partnerId!, partnerName),
                  icon: const Icon(Icons.history, size: 18),
                  tooltip: 'Xem lịch sử thanh toán',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentHistoryDialog(
      BuildContext context, String partnerId, String partnerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Lịch sử thanh toán - $partnerName',
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

  Widget _buildPaymentHistoryTable(String partnerId) {
    return StreamBuilder<List<Transaction>>(
      stream: _db.transactionsDao.watchTransactionsByPartner(partnerId),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        // Sắp xếp mới nhất trước
        final filtered = transactions.toList()
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
                        width: 80,
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
                    final isDebt = t.paymentMethod == 2;
                    final isDebtPayment = t.paymentMethod == 3;
                    final typeLabel = switch (t.paymentMethod) {
                      0 => 'T.Mặt',
                      1 => 'C.Khoản',
                      2 => 'Nợ',
                      3 => 'Trả nợ',
                      _ => '?',
                    };
                    final typeColor = switch (t.paymentMethod) {
                      0 => Colors.green,
                      1 => Colors.blue,
                      2 => Colors.red,
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
                            width: 80,
                            child: Text(
                              DateFormat('dd/MM HH:mm')
                                  .format(t.transactionDate),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${isDebt ? '+' : '-'}${_currencyFormat.format(t.amount)}đ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDebt ? Colors.red : Colors.green,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              t.note ?? '',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
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

  Widget _buildPaymentChip(String label, int value, Color color) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          if (value == 2) _invoicePaymentAmountController.text = '0';
          if (value == 3) _invoicePaymentAmountController.text = '0';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerDebtContent(String partnerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculatePartnerDebt(partnerId),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final totalDebt = (debtInfo['totalDebt'] as num?)?.toDouble() ?? 0.0;
        final totalPaid = (debtInfo['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final remaining = (debtInfo['remaining'] as num?)?.toDouble() ?? 0.0;

        return Column(
          children: [
            // Top row: Lịch sử thanh toán | Hình thức thanh toán
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Lịch sử thanh toán
                  Expanded(
                    flex: 2,
                    child: _buildTransactionHistory(partnerId,
                        title: 'Lịch sử thanh toán'),
                  ),
                  const SizedBox(width: 12),
                  // Right: Payment form
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hình thức thanh toán',
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
                                    _invoicePaymentAmountController.text = '0';
                                  });
                                }
                              },
                              selectedColor: Colors.red[200],
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            ChoiceChip(
                              label: const Text('Trả nợ',
                                  style: TextStyle(fontSize: 10)),
                              selected: _selectedPaymentMethod == 3,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPaymentMethod = 3;
                                    _invoicePaymentAmountController.text = '0';
                                  });
                                }
                              },
                              selectedColor: Colors.purple[200],
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Payment amount input
                        SizedBox(
                          width: 160,
                          height: 36,
                          child: TextField(
                            controller: _selectedPaymentMethod == 3
                                ? _paymentAmountController
                                : _invoicePaymentAmountController,
                            keyboardType: TextInputType.number,
                            enabled: _selectedPaymentMethod != 2,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              suffixText: 'đ',
                              suffixStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                              filled: _selectedPaymentMethod == 2,
                              fillColor: Colors.grey[200],
                              hintText: _selectedPaymentMethod == 3
                                  ? 'Số tiền trả nợ'
                                  : 'Số tiền TT',
                              hintStyle: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Bottom row: Summary boxes in one row
            Row(
              children: [
                Expanded(
                    child: _buildDebtSummaryBoxHorizontal(
                        'Tổng nợ', totalDebt, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildDebtSummaryBoxHorizontal(
                        'Đã trả', totalPaid, Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          remaining > 0 ? Colors.red[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: remaining > 0 ? Colors.red : Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Text(
                          _currencyFormat.format(remaining),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: remaining > 0
                                ? Colors.red[800]
                                : Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebtSummaryBoxHorizontal(
      String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryBoxCompact(String label, double value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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
      {String title = 'Lịch sử thanh toán'}) {
    // Show all transactions (type 0 = Thu/Thanh toán)
    return StreamBuilder<List<Transaction>>(
      stream: _db.transactionsDao.watchTransactionsByPartner(partnerId),
      builder: (context, snapshot) {
        final transactions =
            (snapshot.data ?? []).where((tx) => tx.type == 0).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: transactions.isEmpty
                    ? const Center(
                        child: Text('Chưa có giao dịch',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      )
                    : SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: 24,
                          dataRowMaxHeight: 28,
                          headingRowHeight: 26,
                          columns: const [
                            DataColumn(
                                label: Text('Loại',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Số tiền',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Ngày',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows:
                              List.generate(transactions.take(8).length, (idx) {
                            final tx = transactions[idx];
                            // paymentMethod: 0=Tiền mặt, 1=Chuyển khoản, 2=Nợ, 3=Trả nợ
                            String methodLabel;
                            Color methodColor;
                            switch (tx.paymentMethod) {
                              case 0:
                                methodLabel = 'TM';
                                methodColor = Colors.green;
                                break;
                              case 1:
                                methodLabel = 'CK';
                                methodColor = Colors.blue;
                                break;
                              case 3:
                                methodLabel = 'Trả nợ';
                                methodColor = Colors.purple;
                                break;
                              default:
                                methodLabel = 'Khác';
                                methodColor = Colors.grey;
                            }
                            return DataRow(cells: [
                              DataCell(Text(methodLabel,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: methodColor,
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(
                                _currencyFormat.format(tx.amount),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: methodColor),
                              )),
                              DataCell(Text(
                                DateFormat('dd/MM').format(tx.transactionDate),
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey),
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

    // Get amount based on payment method
    final amount = _selectedPaymentMethod == 3
        ? (double.tryParse(_paymentAmountController.text) ?? 0)
        : (double.tryParse(_invoicePaymentAmountController.text) ?? 0);

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
      // All payment methods save to transaction history with type = 0 (Thu)
      // paymentMethod: 0 = Tiền mặt, 1 = Chuyển khoản, 3 = Trả nợ
      String note;
      switch (_selectedPaymentMethod) {
        case 0:
          note = 'Thanh toán tiền mặt';
          break;
        case 1:
          note = 'Thanh toán chuyển khoản';
          break;
        case 3:
          note = 'Trả nợ';
          break;
        default:
          note = 'Thanh toán';
      }

      await _db.transactionsDao.createTransaction(
        TransactionsCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          partnerId: Value(partnerId),
          invoiceId: const Value(null),
          amount: Value(amount),
          type: const Value(0), // 0 = Thu (all go to Lịch sử thanh toán)
          paymentMethod: Value(_selectedPaymentMethod),
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

    // Chỉ reset các ô nhập tiền, giữ nguyên khách hàng đang chọn
    setState(() {
      _lastSavedInvoice = null;
      _paymentAmountController.clear();
      _invoicePaymentAmountController.clear();
    });
  }
}
