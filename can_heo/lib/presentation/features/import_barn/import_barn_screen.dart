import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/scale_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/farm.dart';
import '../../../domain/entities/cage.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../domain/repositories/i_farm_repository.dart';
import '../../../domain/repositories/i_cage_repository.dart';
import '../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';
import '../pig_types/pig_types_screen.dart';

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

  // New controllers as per requirements
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmWeightController = TextEditingController();
  final TextEditingController _transportFeeController =
      TextEditingController(text: '0');
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _cageController = TextEditingController();

  // Controllers for action row below saved invoices
  final TextEditingController _debtPaymentController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  // Selected invoice for operations
  InvoiceEntity? _selectedInvoice;
  bool _isEditMode = false;

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');

  PartnerEntity? _selectedPartner;
  FarmEntity? _selectedFarm;
  CageEntity? _selectedCage;
  final _invoiceRepo = sl<IInvoiceRepository>();
  final _farmRepo = sl<IFarmRepository>();
  final _cageRepo = sl<ICageRepository>();
  
  // Cache for cage names
  Map<String, String> _cageNames = {};

  // Scale data - nhập trực tiếp từ người dùng
  double _totalMarketWeight = 0.0; // TL Chợ - nhập trực tiếp
  int _totalQuantity = 0;

  @override
  void initState() {
    super.initState();
    _loadCageNames();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scaleInputFocus.requestFocus();
    });
  }
  
  Future<void> _loadCageNames() async {
    final cages = await _cageRepo.getAllCages();
    setState(() {
      _cageNames = {for (var cage in cages) cage.id: cage.name};
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
    _cageController.dispose();
    _debtPaymentController.dispose();
    _discountController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _farmWeight =>
      double.tryParse(_farmWeightController.text.replaceAll(',', '')) ?? 0;
  double get _marketWeight => _totalMarketWeight;
  double get _diffWeight =>
      (_farmWeight - _marketWeight).clamp(0, double.infinity); // Chênh lệch
  double get _pricePerKg =>
      double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _subtotal => _marketWeight * _pricePerKg; // Thành tiền
  double get _transportFee =>
      double.tryParse(_transportFeeController.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () =>
            _saveInvoice(context),
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
            body: Builder(
              builder: (ctx) {
                Responsive.init(ctx);

                return Padding(
                  padding: EdgeInsets.all(Responsive.spacing),
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

  Widget _buildScaleSection(BuildContext context) {
    return Card(
      color: Colors.orange[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ROW 1: Scale display - editable input
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
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _scaleInputController,
                      focusNode: _scaleInputFocus,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[300],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        // Cập nhật TL Chợ khi người dùng nhập
                        final weight = double.tryParse(value) ?? 0;
                        setState(() {
                          _totalMarketWeight = weight;
                        });
                      },
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

            // ROW 2: Summary - 3 items in a row (bỏ phần nhập thủ công)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: _buildCompactSummary(
                          'SỐ HEO NHẬP', Icons.pets, Colors.orange)),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildCompactSummary(
                          'KHỐI LƯỢNG', Icons.scale, Colors.blue)),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildCompactSummary(
                          'SỐ PHIẾU', Icons.receipt, Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
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
            int invoiceCount = todayInvoices.length;

            for (final inv in todayInvoices) {
              totalWeight += inv.totalWeight;
              totalQuantity += inv.totalQuantity;
            }

            if (label.contains('HEO')) {
              value = '$totalQuantity con';
            } else if (label.contains('KHỐI')) {
              value = '${_numberFormat.format(totalWeight)} kg';
            } else if (label.contains('PHIẾU')) {
              value = '$invoiceCount phiếu';
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

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    const fieldHeight = 42.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header - style giống nhập chợ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isEditMode
                    ? Colors.orange.shade600
                    : Colors.green.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.receipt_long,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditMode
                          ? '✏️ CHỈNH SỬA PHIẾU NHẬP'
                          : '📝 THÔNG TIN PHIẾU NHẬP KHO',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon:
                          const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Tạo mới',
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Form - 4 rows layout: 3 rows x 3 cols equal + 1 row ghi chú
            Expanded(
              child: Column(
                children: [
                  // Row 1: Mã + Nhà cung cấp + Trại
                  _buildRowLabels(
                      ['Mã', 'Nhà cung cấp', 'Trại'], [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        // Mã NCC
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _selectedPartner?.id ?? '---',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Nhà cung cấp
                        Expanded(
                          child: BlocBuilder<PartnerBloc, PartnerState>(
                            builder: (context, state) {
                              final partners = state.partners;
                              final safeValue =
                                  partners.contains(_selectedPartner)
                                      ? _selectedPartner
                                      : null;
                              return DropdownButtonFormField<PartnerEntity>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                ),
                                value: safeValue,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black),
                                items: partners
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPartner = value;
                                    _selectedFarm =
                                        null; // Reset farm when partner changes
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Trại - Dropdown
                        Expanded(
                          child: _buildFarmDropdown(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 2: Loại heo + Số lượng + Tồn kho/Tồn chợ
                  _buildRowLabels(['Loại heo', 'Số lượng', 'Tồn kho / Tồn chợ'],
                      [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildPigTypeDropdown()),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSimpleTextField(_quantityController,
                              isDecimal: false),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildCombinedInventoryDisplayField(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 3: Số lô + Chuồng + TL Trại
                  _buildRowLabels(
                      ['Số lô', 'Chuồng', 'TL Trại'], [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSimpleTextField(_batchNumberController),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildCageDropdown(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSimpleTextField(_farmWeightController,
                              isDecimal: true,
                              onChanged: (_) => setState(() {})),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 4: TL Chợ + Chênh lệch + Ghi chú
                  _buildRowLabels(
                      ['TL Chợ', 'Chênh lệch', 'Ghi chú'], [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSimpleTextField(
                            _scaleInputController,
                            isDecimal: true,
                            onChanged: (value) {
                              final weight = double.tryParse(value) ?? 0;
                              setState(() => _totalMarketWeight = weight);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: _diffWeight > 0
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              border: Border.all(
                                  color: _diffWeight > 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _numberFormat.format(_diffWeight),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _diffWeight > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSimpleTextField(_noteController),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildRowLabels(List<String> labels, List<double?> widths) {
    return Row(
      children: List.generate(labels.length, (i) {
        final label = labels[i];
        final width = widths[i];
        if (width != null) {
          return SizedBox(
            width: width,
            child: _buildTableLabel(label),
          );
        } else {
          return Expanded(child: _buildTableLabel(label));
        }
      }).expand((w) => [w, const SizedBox(width: 4)]).toList()
        ..removeLast(),
    );
  }

  Widget _buildTableLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSimpleTextField(
    TextEditingController controller, {
    bool isDecimal = false,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      onChanged: onChanged ?? (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildFormRow1() {
    // Row 1: Mã NCC, Tên NCC
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        final safeValue =
            (partners.contains(_selectedPartner)) ? _selectedPartner : null;

        return Row(
          children: [
            Expanded(
              child: _buildCompactField(
                'Mã NCC',
                Text(
                  _selectedPartner?.id ?? '---',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                icon: Icons.tag,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<PartnerEntity>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Nhà cung cấp',
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.person, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                value: safeValue,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: partners
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child:
                            Text(p.name, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPartner = value),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormRow2() {
    // Row 2: Tên Trại, Loại heo
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            'Tên Trại',
            _farmNameController,
            hintText: 'Nhập tên trại',
            icon: Icons.home_work,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPigTypeDropdown(),
        ),
      ],
    );
  }

  Widget _buildFormRow3() {
    // Row 3: Số lô, Tồn kho, Tồn chợ
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            'Số lô',
            _batchNumberController,
            hintText: 'Số lô',
            icon: Icons.numbers,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInventoryDisplayField(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMarketInventoryDisplayField(),
        ),
      ],
    );
  }

  Widget _buildFormRow4() {
    // Row 4: Số lượng, TL Trại, TL Chợ, Chênh lệch
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
            icon: Icons.scale,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'TL Chợ (kg)',
            _scaleInputController,
            hintText: 'Nhập TL',
            isDecimal: true,
            icon: Icons.balance,
            onChanged: (value) {
              final weight = double.tryParse(value) ?? 0;
              setState(() => _totalMarketWeight = weight);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactField(
            'Chênh lệch (kg)',
            Text(
              _numberFormat.format(_diffWeight),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _diffWeight > 0
                    ? Colors.red.shade700
                    : Colors.grey.shade600,
              ),
            ),
            icon: Icons.compare_arrows,
            bgColor:
                _diffWeight > 0 ? Colors.red.shade50 : Colors.grey.shade100,
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
      icon: Icons.edit_note,
    );
  }

  Widget _buildCompactField(String label, Widget child,
      {IconData? icon, Color? bgColor}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          prefixIcon: icon != null ? Icon(icon, size: 18) : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
        ),
        child: child,
      ),
    );
  }

  Widget _buildCompactTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    bool isNumber = false,
    bool isDecimal = false,
    IconData? icon,
    void Function(String)? onChanged,
  }) {
    return TextField(
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
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildFarmDropdown() {
    if (_selectedPartner == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey[100],
        ),
        child: const Text(
          'Chọn NCC trước',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<List<FarmEntity>>(
      stream: _farmRepo.watchFarmsByPartner(_selectedPartner!.id),
      builder: (context, snapshot) {
        final farms = snapshot.data ?? [];

        // Kiểm tra xem farm đã chọn còn trong list không
        final safeValue = farms.contains(_selectedFarm) ? _selectedFarm : null;

        return DropdownButtonFormField<FarmEntity>(
          value: safeValue,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: farms.isEmpty ? 'Chưa có trại' : 'Chọn trại',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          items: farms
              .map((farm) => DropdownMenuItem(
                    value: farm,
                    child:
                        Text(farm.name, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedFarm = value),
        );
      },
    );
  }

  Widget _buildCageDropdown() {
    return StreamBuilder<List<CageEntity>>(
      stream: _cageRepo.watchAllCages(),
      builder: (context, snapshot) {
        final cages = snapshot.data ?? [];

        return DropdownButtonFormField<CageEntity>(
          value: _selectedCage != null && cages.contains(_selectedCage) ? _selectedCage : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: cages.isEmpty ? 'Chưa có chuồng' : 'Chọn chuồng',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          items: cages
              .map((cage) => DropdownMenuItem(
                    value: cage,
                    child: Text(cage.name, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (value) => setState(() {
            _selectedCage = value;
            _cageController.text = value?.name ?? '';
          }),
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
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.pets, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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

  // Tồn kho = Type 0 - Type 1
  // Tồn chợ = Type 3 + Type 1 - Type 2 - Type 0
  Widget _buildCombinedInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildCombinedInventoryContainer(0, 0);
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest4(
        _invoiceRepo.watchInvoices(type: 0), // Nhập kho (+kho, -chợ)
        _invoiceRepo.watchInvoices(type: 1), // Xuất kho (-kho, +chợ)
        _invoiceRepo.watchInvoices(type: 2), // Xuất chợ (-chợ)
        _invoiceRepo.watchInvoices(type: 3), // Nhập chợ (+chợ)
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
        final importBarn = snapshot.data![0];   // Type 0: Nhập kho
        final exportBarn = snapshot.data![1];   // Type 1: Xuất kho
        final exportMarket = snapshot.data![2]; // Type 2: Xuất chợ
        final importMarket = snapshot.data![3]; // Type 3: Nhập chợ

        int barnInventory = 0;
        int marketInventory = 0;

        // Tồn kho = Nhập kho (Type 0) - Xuất kho (Type 1)
        for (final inv in importBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              barnInventory += item.quantity;
          }
        }
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              barnInventory -= item.quantity;
          }
        }

        // Tồn chợ = Nhập chợ (Type 3) + Xuất kho (Type 1) - Xuất chợ (Type 2) - Nhập kho (Type 0)
        for (final inv in importMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory += item.quantity;
          }
        }
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory += item.quantity;
          }
        }
        for (final inv in exportMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory -= item.quantity;
          }
        }
        for (final inv in importBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory -= item.quantity;
          }
        }

        return _buildCombinedInventoryContainer(barnInventory, marketInventory);
      },
    );
  }

  Widget _buildInventoryDisplayFieldCompact() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainerCompact(0);
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest2(
        _invoiceRepo.watchInvoices(type: 0),
        _invoiceRepo.watchInvoices(type: 2),
        (List<InvoiceEntity> imports, List<InvoiceEntity> exports) =>
            [imports, exports],
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
        final importSnap = snapshot.data![0];
        final exportSnap = snapshot.data![1];
        int imported = 0;
        int exported = 0;
        for (final inv in importSnap) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              imported += item.quantity;
          }
        }
        for (final inv in exportSnap) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              exported += item.quantity;
          }
        }
        final availableQty = imported - exported;
        return _buildInventoryContainerCompact(availableQty);
      },
    );
  }

  // Tồn chợ = Type 3 + Type 1 - Type 2 - Type 0
  Widget _buildMarketInventoryDisplayFieldCompact() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainerCompact(0);
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest4(
        _invoiceRepo.watchInvoices(type: 0), // Nhập kho (-chợ)
        _invoiceRepo.watchInvoices(type: 1), // Xuất kho (+chợ)
        _invoiceRepo.watchInvoices(type: 2), // Xuất chợ (-chợ)
        _invoiceRepo.watchInvoices(type: 3), // Nhập chợ (+chợ)
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
        final importBarn = snapshot.data![0];   // Type 0
        final exportBarn = snapshot.data![1];   // Type 1
        final exportMarket = snapshot.data![2]; // Type 2
        final importMarket = snapshot.data![3]; // Type 3

        int marketInventory = 0;

        // + Nhập chợ (Type 3)
        for (final inv in importMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory += item.quantity;
          }
        }
        // + Xuất kho (Type 1)
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory += item.quantity;
          }
        }
        // - Xuất chợ (Type 2)
        for (final inv in exportMarket) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory -= item.quantity;
          }
        }
        // - Nhập kho (Type 0)
        for (final inv in importBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              marketInventory -= item.quantity;
          }
        }

        final displayQty = marketInventory < 0 ? 0 : marketInventory;
        return _buildInventoryContainerCompact(displayQty);
      },
    );
  }

  // Tồn kho = Nhập kho (0) - Xuất kho (1)
  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainer(0, 'Tồn kho');
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest2(
        _invoiceRepo.watchInvoices(type: 0), // Nhập kho (hàng thừa) (+)
        _invoiceRepo.watchInvoices(type: 1), // Xuất kho ra chợ (-)
        (List<InvoiceEntity> imports, List<InvoiceEntity> exports) =>
            [imports, exports],
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
        final importBarn = snapshot.data![0];  // Type 0: Nhập kho (+)
        final exportBarn = snapshot.data![1];  // Type 1: Xuất kho (-)
        int available = 0;
        
        // + Nhập kho (Type 0)
        for (final inv in importBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available += item.quantity;
          }
        }
        
        // - Xuất kho (Type 1)
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType)
              available -= item.quantity;
          }
        }
        
        return _buildInventoryContainer(available, 'Tồn kho');
      },
    );
  }

  // Tồn chợ = Nhập chợ (3) + Xuất kho (1) - Xuất chợ (2) - Nhập kho (0)
  Widget _buildMarketInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainer(0, 'Tồn chợ');
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
        
        return _buildInventoryContainer(available, 'Tồn chợ');
      },
    );
  }

  Widget _buildCombinedInventoryContainer(int barnQty, int marketQty) {
    // Không cho phép hiển thị số âm
    final displayBarnQty = barnQty < 0 ? 0 : barnQty;
    final displayMarketQty = marketQty < 0 ? 0 : marketQty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Text(
              '$displayBarnQty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.green.shade300,
          ),
          Expanded(
            child: Text(
              '$displayMarketQty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryContainerCompact(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$qty',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildInventoryContainer(int qty, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$qty con',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  // Widget kết hợp Số lượng + Tồn kho
  Widget _buildQuantityWithInventoryField() {
    final pigType = _pigTypeController.text.trim();

    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest2(
        _invoiceRepo.watchInvoices(type: 0),
        _invoiceRepo.watchInvoices(type: 2),
        (List<InvoiceEntity> imports, List<InvoiceEntity> exports) =>
            [imports, exports],
      ),
      builder: (context, snapshot) {
        int availableQty = 0;

        if (snapshot.hasData && pigType.isNotEmpty) {
          final importSnap = snapshot.data![0];
          final exportSnap = snapshot.data![1];
          int imported = 0;
          int exported = 0;

          for (final inv in importSnap) {
            for (final item in inv.details) {
              if ((item.pigType ?? '').trim() == pigType)
                imported += item.quantity;
            }
          }
          for (final inv in exportSnap) {
            for (final item in inv.details) {
              if ((item.pigType ?? '').trim() == pigType)
                exported += item.quantity;
            }
          }
          availableQty = imported - exported;
        }

        return Row(
          children: [
            // Số lượng input (2/3 width)
            Expanded(
              flex: 2,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.format_list_numbered, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  suffixIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          setState(() =>
                              _quantityController.text = '${current + 1}');
                        },
                        child: const Icon(Icons.keyboard_arrow_up, size: 18),
                      ),
                      InkWell(
                        onTap: () {
                          final current =
                              int.tryParse(_quantityController.text) ?? 1;
                          if (current > 1) {
                            setState(() =>
                                _quantityController.text = '${current - 1}');
                          }
                        },
                        child: const Icon(Icons.keyboard_arrow_down, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Tồn kho display (1/3 width)
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$availableQty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityFieldWithButtons() {
    return TextField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.format_list_numbered, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        suffixIcon: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                final current = int.tryParse(_quantityController.text) ?? 1;
                setState(() => _quantityController.text = '${current + 1}');
              },
              child: const Icon(Icons.keyboard_arrow_up, size: 18),
            ),
            InkWell(
              onTap: () {
                final current = int.tryParse(_quantityController.text) ?? 1;
                if (current > 1) {
                  setState(() => _quantityController.text = '${current - 1}');
                }
              },
              child: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ],
        ),
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
                ? () => _isEditMode
                    ? _updateInvoice(context)
                    : _saveInvoice(context)
                : null,
            icon: Icon(_isEditMode ? Icons.edit : Icons.save),
            label: Text(_isEditMode ? 'CẬP NHẬT' : 'LƯU (F4)'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  canSave ? (_isEditMode ? Colors.orange : null) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveInvoice() {
    // Lấy weight từ ô nhập trực tiếp
    final weight =
        double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
    final hasWeight = weight > 0;

    return _selectedPartner != null &&
        _pigTypeController.text.isNotEmpty &&
        hasWeight;
  }

  void _saveInvoice(BuildContext context) {
    // Lấy weight từ ô nhập trực tiếp
    final weight =
        double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;

    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số cân!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cập nhật _totalMarketWeight từ ô nhập
    setState(() {
      _totalMarketWeight = weight;
    });

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
            batchNumber: _batchNumberController.text.isNotEmpty
                ? _batchNumberController.text
                : null,
            pigType: pigType,
          ),
        );

    // Update invoice info - Chỉ lưu thông tin cơ bản (không tính tiền)
    final farmName = _selectedFarm?.name ?? '';
    final cage = _cageController.text.trim();
    final otherNote = _noteController.text.trim();

    List<String> noteParts = [];
    if (farmName.isNotEmpty) noteParts.add('Trại: $farmName');
    if (cage.isNotEmpty) noteParts.add('Chuồng: $cage');
    if (otherNote.isNotEmpty) noteParts.add(otherNote);
    final note = noteParts.join(' | ');

    context.read<WeighingBloc>().add(
          WeighingInvoiceUpdated(
            partnerId: _selectedPartner!.id,
            partnerName: _selectedPartner!.name,
            cageId: _selectedCage?.id,
            pricePerKg: 0, // Không tính giá
            deduction: _farmWeight, // Store farm weight here
            discount: 0, // Không tính tiền
            note: note,
            finalAmount: 0, // Không tính tiền
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
    _farmWeightController.clear();
    _transportFeeController.text = '0';
    _paymentAmountController.clear();
    _cageController.clear();
    setState(() {
      _selectedPartner = null;
      _selectedFarm = null;
      _selectedCage = null;
      _selectedInvoice = null;
      _isEditMode = false;
      _totalMarketWeight = 0;
      _totalQuantity = 0;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(0));
    _scaleInputFocus.requestFocus();
  }

  /// Load invoice data into form for editing
  void _loadInvoiceToForm(InvoiceEntity invoice) {
    // Extract farm name, cage, and note from invoice note
    String farmName = '';
    String cage = '';
    String otherNote = '';

    if (invoice.note != null && invoice.note!.isNotEmpty) {
      final parts = invoice.note!.split(' | ');
      for (final part in parts) {
        if (part.startsWith('Trại: ')) {
          farmName = part.replaceFirst('Trại: ', '');
        } else if (part.startsWith('Chuồng: ')) {
          cage = part.replaceFirst('Chuồng: ', '');
        } else {
          otherNote = otherNote.isEmpty ? part : '$otherNote | $part';
        }
      }
    }

    final pigType =
        invoice.details.isNotEmpty ? (invoice.details.first.pigType ?? '') : '';
    final batchNumber = invoice.details.isNotEmpty
        ? (invoice.details.first.batchNumber ?? '')
        : '';

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
            : PartnerEntity(
                id: invoice.partnerId ?? '',
                name: invoice.partnerName ?? '',
                isSupplier: true,
                currentDebt: 0),
      );

      // Load form fields - Note: farmName will be matched to dropdown later
      _selectedFarm = null; // Reset, user needs to select again
      _noteController.text = otherNote;
      _cageController.text = cage;
      _pigTypeController.text = pigType;
      _batchNumberController.text = batchNumber;
      _quantityController.text = '${invoice.totalQuantity}';
      _farmWeightController.text =
          farmWeight > 0 ? farmWeight.toStringAsFixed(1) : '';
      _priceController.text =
          invoice.pricePerKg > 0 ? invoice.pricePerKg.toStringAsFixed(0) : '';
      _transportFeeController.text = transportFee.toStringAsFixed(0);
      _paymentAmountController.text =
          paidAmount > 0 ? paidAmount.toStringAsFixed(0) : '';

      // Load weighing data - nhập trực tiếp vào ô số cân
      _scaleInputController.text = marketWeight.toStringAsFixed(1);
      _totalMarketWeight = marketWeight;
      _totalQuantity = invoice.totalQuantity;
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
      final farmName = _selectedFarm?.name ?? '';
      final note = farmName.isNotEmpty
          ? 'Trại: $farmName${_noteController.text.isNotEmpty ? ' | ${_noteController.text}' : ''}'
          : _noteController.text;

      // Calculate payment amount
      final paymentAmount =
          double.tryParse(_paymentAmountController.text.replaceAll(',', '')) ??
              _subtotal + _transportFee;

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

      debugPrint(
          'Form quantity: $formQuantity, Final quantity: $finalQuantity');

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
        debugPrint(
            'Updating weighing item: ${_selectedInvoice!.details.first.id}');
        final updatedItem = _selectedInvoice!.details.first.copyWith(
          pigType: pigType,
          batchNumber: _batchNumberController.text.isNotEmpty
              ? _batchNumberController.text
              : null,
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
          invoicePigTypes[pigType] =
              (invoicePigTypes[pigType] ?? 0) + item.quantity;
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

  Future<void> _confirmDeleteImportInvoice(
      BuildContext context, InvoiceEntity invoice) async {
    // First check if we can delete
    final canDelete = await _canDeleteImportInvoice(invoice);

    if (!canDelete) {
      if (context.mounted) {
        // Get pig type info for better error message
        String pigTypes =
            invoice.details.map((d) => d.pigType ?? 'N/A').toSet().join(', ');

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

    // Tìm các phiếu chiết khấu/trả nợ liên quan đến phiếu này
    final allInvoices = await _invoiceRepo.watchInvoices(type: 0).first;
    final relatedInvoices = allInvoices.where((inv) {
      final note = inv.note ?? '';
      if (note.contains('[TRẢ NỢ]') || note.contains('[CHIẾT KHẤU]')) {
        // Check if this invoice is related to the one we're deleting
        return note.contains('Phiếu gốc: ${invoice.id}');
      }
      return false;
    }).toList();

    // Build confirmation message
    String confirmMessage = 'Bạn có chắc muốn xóa phiếu này?';
    if (relatedInvoices.isNotEmpty) {
      final debtCount = relatedInvoices
          .where((inv) => inv.note?.contains('[TRẢ NỢ]') ?? false)
          .length;
      final discountCount = relatedInvoices
          .where((inv) => inv.note?.contains('[CHIẾT KHẤU]') ?? false)
          .length;

      List<String> relatedInfo = [];
      if (debtCount > 0) relatedInfo.add('$debtCount phiếu trả nợ');
      if (discountCount > 0) relatedInfo.add('$discountCount phiếu chiết khấu');

      confirmMessage =
          'Phiếu này có ${relatedInfo.join(' và ')} liên quan.\nXóa phiếu sẽ xóa luôn các phiếu liên quan.\n\nBạn có chắc muốn xóa?';
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu'),
        content: Text(confirmMessage),
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
      // Xóa các phiếu chiết khấu/trả nợ liên quan trước
      for (final relatedInv in relatedInvoices) {
        await _invoiceRepo.deleteInvoice(relatedInv.id);
      }

      // Xóa phiếu gốc
      await _invoiceRepo.deleteInvoice(invoice.id);

      if (context.mounted) {
        String message = 'Đã xóa phiếu';
        if (relatedInvoices.isNotEmpty) {
          message += ' và ${relatedInvoices.length} phiếu liên quan';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  // Xóa phiếu nhập kho từ DataTable
  Future<void> _confirmDeleteInvoice(InvoiceEntity invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa phiếu nhập kho #${invoice.invoiceCode ?? invoice.id.substring(0, 8)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _invoiceRepo.deleteInvoice(invoice.id);
      if (mounted) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa phiếu nhập kho!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: _invoiceRepo.watchInvoices(type: 0),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var invoices = snapshot.data!;
        if (invoices.isEmpty)
          return const Center(child: Text('Chưa có phiếu nhập nào'));

        // Tách phiếu nhập kho (gốc) và phiếu chiết khấu/trả nợ
        final importInvoices = invoices.where((inv) {
          final isDebtPayment = inv.note?.contains('[TRẢ NỢ]') ?? false;
          final isDiscount = inv.note?.contains('[CHIẾT KHẤU]') ?? false;
          return !isDebtPayment && !isDiscount;
        }).toList();

        // Tạo map: phiếu gốc ID -> danh sách phiếu liên quan (chiết khấu/trả nợ)
        final Map<String, List<InvoiceEntity>> relatedPayments = {};
        for (final inv in invoices) {
          final note = inv.note ?? '';
          if (note.contains('[TRẢ NỢ]') || note.contains('[CHIẾT KHẤU]')) {
            // Extract original invoice ID from note - ID nằm sau "Phiếu gốc: " đến cuối hoặc đến ký tự đặc biệt
            final match = RegExp(r'Phiếu gốc:\s*(.+)$').firstMatch(note);
            if (match != null) {
              final originalId = match.group(1)!.trim();
              relatedPayments.putIfAbsent(originalId, () => []);
              relatedPayments[originalId]!.add(inv);
            }
          }
        }

        // Tạo map: invoice ID -> STT (theo nhóm phiếu gốc)
        final Map<String, int> invoiceSttMap = {};
        int sttCounter = 0;
        for (final inv in importInvoices) {
          sttCounter++;
          invoiceSttMap[inv.id] = sttCounter;
          // Gán cùng STT cho các phiếu liên quan
          final related = relatedPayments[inv.id] ?? [];
          for (final r in related) {
            invoiceSttMap[r.id] = sttCounter;
          }
        }

        // Tính tổng chiết khấu/trả nợ cho mỗi phiếu gốc
        final Map<String, double> totalRelatedPayments = {};
        for (final entry in relatedPayments.entries) {
          double total = 0;
          for (final r in entry.value) {
            total += r.finalAmount.abs();
          }
          totalRelatedPayments[entry.key] = total;
        }

        // Tính công nợ cộng dồn theo NCC (nhà cung cấp)
        // Sắp xếp phiếu gốc theo thời gian từ cũ đến mới để tính cộng dồn
        final sortedImportInvoices = List<InvoiceEntity>.from(importInvoices)
          ..sort((a, b) => a.createdDate.compareTo(b.createdDate));

        // Map: partnerName -> danh sách phiếu gốc theo thứ tự thời gian (cũ -> mới)
        // Sử dụng partnerName thay vì partnerId để nhóm đúng theo NCC
        final Map<String, List<InvoiceEntity>> invoicesByPartner = {};
        for (final inv in sortedImportInvoices) {
          final partnerKey = inv.partnerName ?? inv.partnerId ?? 'unknown';
          invoicesByPartner.putIfAbsent(partnerKey, () => []);
          invoicesByPartner[partnerKey]!.add(inv);
        }

        // Tính công nợ cộng dồn cho mỗi phiếu theo NCC
        // Phiếu mới nhất sẽ có công nợ = tổng công nợ các phiếu cũ + công nợ phiếu hiện tại
        final Map<String, double> cumulativeDebtByInvoice = {};
        for (final partnerKey in invoicesByPartner.keys) {
          final partnerInvoices = invoicesByPartner[partnerKey]!;
          double runningDebt = 0;
          for (final inv in partnerInvoices) {
            // Tính công nợ riêng của phiếu này
            final transportFee = inv.discount;
            final subtotal = inv.totalWeight * inv.pricePerKg;
            final totalImport = subtotal + transportFee;
            final paidAmount = inv.finalAmount;
            final relatedTotal = totalRelatedPayments[inv.id] ?? 0;
            final invoiceDebt = totalImport - paidAmount - relatedTotal;

            // Cộng dồn công nợ
            runningDebt += invoiceDebt;
            cumulativeDebtByInvoice[inv.id] = runningDebt;
          }
        }

        return Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU NHẬP ĐÃ LƯU (${importInvoices.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange),
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
                      columnSpacing: 16,
                      horizontalMargin: 10,
                      headingRowHeight: 40,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      dataTextStyle: const TextStyle(fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Mã phiếu')),
                        DataColumn(label: Text('Thời gian')),
                        DataColumn(label: Text('Tên NCC')),
                        DataColumn(label: Text('Tên Trại')),
                        DataColumn(label: Text('Chuồng')),
                        DataColumn(label: Text('Loại heo')),
                        DataColumn(label: Text('Số lô')),
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('TL Trại')),
                        DataColumn(label: Text('TL Chợ')),
                        DataColumn(label: Text('Chênh lệch')),
                        DataColumn(label: Text('Hình thức')),
                        DataColumn(label: Text('Thao tác')),
                      ],
                      rows: List.generate(invoices.length, (idx) {
                        final inv = invoices[idx];
                        final dateFormat = DateFormat('dd/MM HH:mm');

                        // Get STT from map (grouped by original invoice)
                        final stt = invoiceSttMap[inv.id] ?? (idx + 1);

                        // Check if this is a debt payment or discount invoice

                        final isDebtPayment =
                            inv.note?.contains('[TRẢ NỢ]') ?? false;
                        final isDiscount =
                            inv.note?.contains('[CHIẾT KHẤU]') ?? false;
                        final status = isDiscount
                            ? 'Chiết khấu'
                            : (isDebtPayment ? 'Trả nợ' : 'Nhập kho');

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

                        if (isDiscount || isDebtPayment) {
                          // Chiết khấu/Trả nợ: không hiển thị công nợ riêng
                          subtotal = 0;
                          totalImport = 0;
                          paidAmount = inv.finalAmount.abs();
                          remainingDebt =
                              0; // Không hiển thị công nợ cho dòng này
                        } else {
                          // Nhập kho: công nợ = công nợ cộng dồn theo NCC
                          subtotal = marketWeight * inv.pricePerKg;
                          totalImport = subtotal + transportFee;
                          paidAmount = inv.finalAmount;
                          // Sử dụng công nợ cộng dồn theo NCC thay vì công nợ riêng
                          remainingDebt = cumulativeDebtByInvoice[inv.id] ?? 0;
                        }

                        // Extract farm name from note, and get cage name from cageId
                        String farmName = '';
                        String cageName = '';
                        
                        // Get cage name from cageId if available
                        if (inv.cageId != null) {
                          cageName = _cageNames[inv.cageId] ?? inv.cageId!;
                        }
                        
                        if (inv.note != null) {
                          final parts = inv.note!.split(' | ');
                          for (final part in parts) {
                            if (part.startsWith('Trại: ')) {
                              farmName = part.replaceFirst('Trại: ', '');
                            } else if (part.startsWith('Chuồng: ') && cageName.isEmpty) {
                              // Fallback to note if cageId not available
                              cageName = part.replaceFirst('Chuồng: ', '');
                            }
                          }
                        }

                        final pigType = inv.details.isNotEmpty
                            ? (inv.details.first.pigType ?? '-')
                            : '-';
                        final batchNumber = inv.details.isNotEmpty
                            ? (inv.details.first.batchNumber ?? '-')
                            : '-';

                        final isSelected = _selectedInvoice?.id == inv.id;

                        return DataRow(
                            selected: isSelected,
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
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
                              DataCell(Center(child: Text('$stt'))),
                              // Mã phiếu
                              DataCell(Text(
                                inv.invoiceCode ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              )),
                              DataCell(
                                  Text(dateFormat.format(inv.createdDate))),
                              DataCell(SizedBox(
                                width: 80,
                                child: Text(inv.partnerName ?? 'NCC',
                                    overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(SizedBox(
                                width: 60,
                                child: Text(farmName,
                                    overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(SizedBox(
                                width: 50,
                                child:
                                    Text(cageName, overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(Text(pigType)),
                              DataCell(Text(batchNumber)),
                              DataCell(Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('${inv.totalQuantity}'))),
                              DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_numberFormat.format(farmWeight.toInt())}'),
                              )),
                              DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_numberFormat.format(marketWeight.toInt())}'),
                              )),
                              DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_numberFormat.format(wastage.toInt())}',
                                  style: TextStyle(
                                    color:
                                        wastage > 0 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              )),
                              // Status column - màu theo loại phiếu
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDiscount
                                        ? Colors.orange.shade100
                                        : (isDebtPayment
                                            ? Colors.green.shade100
                                            : Colors.blue.shade100),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDiscount
                                          ? Colors.orange.shade700
                                          : (isDebtPayment
                                              ? Colors.green.shade700
                                              : Colors.blue),
                                    ),
                                  ),
                                ),
                              ),
                              // Delete button
                              DataCell(
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      size: 18, color: Colors.red.shade600),
                                  onPressed: () => _confirmDeleteInvoice(inv),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Xóa phiếu',
                                ),
                              ),
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
}

class _ImportBarnFormControllers {
  final TextEditingController scaleInputController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController pigTypeController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController farmWeightController = TextEditingController();
  final TextEditingController transportFeeController =
      TextEditingController(text: '0');
  final TextEditingController paymentAmountController = TextEditingController();
  final TextEditingController debtPaymentController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final FocusNode scaleInputFocus = FocusNode();

  void clear() {
    scaleInputController.clear();
    batchNumberController.clear();
    pigTypeController.clear();
    noteController.clear();
    priceController.clear();
    quantityController.text = '1';
    farmNameController.clear();
    farmWeightController.clear();
    transportFeeController.text = '0';
    paymentAmountController.clear();
    debtPaymentController.clear();
    discountController.clear();
  }

  void dispose() {
    scaleInputController.dispose();
    batchNumberController.dispose();
    pigTypeController.dispose();
    noteController.dispose();
    priceController.dispose();
    quantityController.dispose();
    farmNameController.dispose();
    farmWeightController.dispose();
    transportFeeController.dispose();
    paymentAmountController.dispose();
    debtPaymentController.dispose();
    discountController.dispose();
    scaleInputFocus.dispose();
  }
}
