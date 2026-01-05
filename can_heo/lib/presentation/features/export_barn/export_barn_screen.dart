import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive.dart';
import '../../../domain/entities/cage.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/farm.dart';
import '../../../domain/repositories/i_cage_repository.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../domain/repositories/i_farm_repository.dart';
import '../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';
import '../pig_types/pig_types_screen.dart';

/// Màn hình Xuất Kho - Xuất heo từ kho ra cho NCC (trả heo, hoàn hàng cho NCC)
/// Type = 1 (Xuất kho)
class ExportBarnScreen extends StatelessWidget {
  const ExportBarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeighingBloc>(
          create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(1)),
        ),
        BlocProvider<PartnerBloc>(
          create: (_) => sl<PartnerBloc>()..add(const LoadPartners(true)),
        ),
      ],
      child: const _ExportBarnView(),
    );
  }
}

class _ExportBarnView extends StatefulWidget {
  const _ExportBarnView();

  @override
  State<_ExportBarnView> createState() => _ExportBarnViewState();
}

class _ExportBarnViewState extends State<_ExportBarnView> {
  // Controllers
  final TextEditingController _scaleInputController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmWeightController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _cageController = TextEditingController();

  // Selected invoice for operations
  InvoiceEntity? _selectedInvoice;
  bool _isEditMode = false;

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  PartnerEntity? _selectedPartner;
  FarmEntity? _selectedFarm;
  CageEntity? _selectedCage;
  final _invoiceRepo = sl<IInvoiceRepository>();
  final _farmRepo = sl<IFarmRepository>();
  final _cageRepo = sl<ICageRepository>();

  // Scale data - nhập trực tiếp từ người dùng
  double _totalWeight = 0.0;

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
    _paymentAmountController.dispose();
    _cageController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  // Calculations
  double get _weight => _totalWeight;
  double get _pricePerKg =>
      double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _subtotal => _weight * _pricePerKg;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () =>
            _saveInvoice(context),
      },
      child: Focus(
        autofocus: true,
        child: BlocListener<WeighingBloc, WeighingState>(
          listener: (context, state) {
            if (state.status == WeighingStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã lưu phiếu xuất kho!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              _resetForm();
            } else if (state.status == WeighingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Lỗi không xác định'),
                  backgroundColor: Colors.brown,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Phiếu Xuất Kho'),
              backgroundColor: Colors.brown[100],
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

                // Responsive layout cho mobile
                if (Responsive.isMobile || Responsive.isTablet) {
                  return _buildMobileLayout(context);
                }

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
                            // Nửa phải: để trống hoặc có thể thêm nội dung khác
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

  /// Mobile layout - single column, scrollable
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Form thông tin phiếu
          _buildMobileInvoiceForm(context),
          const SizedBox(height: 16),
          // Danh sách phiếu đã lưu
          SizedBox(
            height: 400,
            child: _buildSavedInvoicesGrid(context),
          ),
        ],
      ),
    );
  }

  /// Mobile form - stacked fields
  Widget _buildMobileInvoiceForm(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isEditMode ? Colors.orange.shade600 : Colors.brown.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.receipt_long,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'CHỈNH SỬA PHIẾU' : 'THÔNG TIN PHIẾU XUẤT KHO',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isEditMode)
                    TextButton(
                      onPressed: _resetForm,
                      child: const Text('Tạo mới', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Nhà cung cấp
            _buildMobileLabel('Nhà cung cấp'),
            BlocBuilder<PartnerBloc, PartnerState>(
              builder: (context, state) {
                final partners = state.partners;
                return DropdownButtonFormField<PartnerEntity>(
                  isExpanded: true,
                  decoration: _mobileInputDecoration('Chọn NCC'),
                  initialValue: partners.contains(_selectedPartner) ? _selectedPartner : null,
                  items: partners.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPartner = value;
                      _selectedFarm = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Trại
            _buildMobileLabel('Trại'),
            _buildFarmDropdown(),
            const SizedBox(height: 12),

            // Loại heo
            _buildMobileLabel('Loại heo'),
            _buildPigTypeDropdown(),
            const SizedBox(height: 12),

            // Row: Số lượng + Trọng lượng
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMobileLabel('Số lượng'),
                      _buildQuantityFieldWithButtons(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMobileLabel('Trọng lượng (kg)'),
                      _buildSimpleTextField(
                        _scaleInputController,
                        isDecimal: true,
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0;
                          setState(() => _totalWeight = weight);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chuồng
            _buildMobileLabel('Chuồng'),
            _buildCageDropdown(),
            const SizedBox(height: 12),

            // Lý do xuất
            _buildMobileLabel('Lý do xuất'),
            _buildSimpleTextField(_farmNameController),
            const SizedBox(height: 12),

            // Ghi chú
            _buildMobileLabel('Ghi chú'),
            _buildSimpleTextField(_noteController),
            const SizedBox(height: 16),

            // Tồn kho display
            _buildMobileLabel('Tồn kho'),
            _buildInventoryDisplayField(),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _canSaveInvoice()
                        ? () => _isEditMode ? _updateInvoice(context) : _saveInvoice(context)
                        : null,
                    icon: Icon(_isEditMode ? Icons.edit : Icons.save),
                    label: Text(_isEditMode ? 'CẬP NHẬT' : 'LƯU PHIẾU'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _canSaveInvoice() ? Colors.brown : Colors.grey,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _mobileInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildScaleSection(BuildContext context) {
    return Card(
      color: Colors.brown[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scale display - editable input
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown, width: 2),
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
                        color: Colors.brown[800],
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[300],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        final weight = double.tryParse(value) ?? 0;
                        setState(() {
                          _totalWeight = weight;
                        });
                      },
                    ),
                  ),
                  Text(
                    ' kg',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Summary
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: _buildCompactSummary(
                          'SỐ HEO XUẤT', Icons.pets, Colors.brown)),
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
        stream: _invoiceRepo.watchInvoices(type: 1), // Type 1 = Xuất kho
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
                        fontSize: 14,
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
                    : Colors.brown.shade600,
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
                          ? '✏️ CHỈNH SỬA PHIẾU XUẤT KHO'
                          : '📝 THÔNG TIN PHIẾU XUẤT KHO',
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
                  // Row 1: Nhà cung cấp + Trại + Lý do xuất
                  _buildRowLabels(['Nhà cung cấp', 'Trại', 'Lý do xuất'],
                      [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
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
                                  hintText: 'Chọn NCC',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                ),
                                initialValue: safeValue,
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
                        const SizedBox(width: 4),
                        // Lý do xuất
                        Expanded(
                          child: _buildSimpleTextField(_farmNameController),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 2: Số lô + Loại heo + Tồn kho
                  _buildRowLabels(
                      ['Số lô', 'Loại heo', 'Tồn kho'], [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSimpleTextField(_batchNumberController),
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: _buildPigTypeDropdown()),
                        const SizedBox(width: 4),
                        Expanded(child: _buildInventoryDisplayField()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 3: Số lượng + Trọng lượng (kg) + Chuồng
                  _buildRowLabels(['Số lượng', 'Trọng lượng (kg)', 'Chuồng'],
                      [null, null, null]),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildQuantityFieldWithButtons()),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSimpleTextField(
                            _scaleInputController,
                            isDecimal: true,
                            onChanged: (value) {
                              final weight = double.tryParse(value) ?? 0;
                              setState(() => _totalWeight = weight);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildCageDropdown(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Row 4: Ghi chú
                  _buildRowLabels(['Ghi chú'], [null]),
                  Expanded(
                    child: _buildSimpleTextField(_noteController),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildFarmDropdown() {
    if (_selectedPartner == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
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
              style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
            ),
          );
        }

        return DropdownButtonFormField<FarmEntity>(
          initialValue: _selectedFarm,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.home_work, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          hint: const Text('Chọn trại', style: TextStyle(fontSize: 13)),
          items: farms.map((farm) {
            return DropdownMenuItem<FarmEntity>(
              value: farm,
              child: Text(farm.name, style: const TextStyle(fontSize: 13)),
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
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<PartnerEntity>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Tên NCC',
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.business, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                initialValue: safeValue,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: partners
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 13)),
                        ))
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
          child: _buildCageDropdown(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Lý do xuất',
            _farmNameController,
            hintText: 'Trả heo, hoàn hàng...',
            icon: Icons.info_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow3() {
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
    return Row(
      children: [
        Expanded(
          child: _buildQuantityFieldWithButtons(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactTextField(
            'Trọng lượng (kg)',
            _scaleInputController,
            hintText: 'Nhập TL',
            isDecimal: true,
            icon: Icons.scale,
            onChanged: (value) {
              final weight = double.tryParse(value) ?? 0;
              setState(() => _totalWeight = weight);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormRow5() {
    // Chỉ có Ghi chú - bỏ Đơn giá và Thành tiền
    return _buildCompactTextField(
      'Ghi chú',
      _noteController,
      hintText: 'Ghi chú...',
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

  Widget _buildCageDropdown() {
    return StreamBuilder<List<CageEntity>>(
      stream: _cageRepo.watchAllCages(),
      builder: (context, snapshot) {
        final cages = snapshot.data ?? [];

        return DropdownButtonFormField<CageEntity>(
          initialValue: _selectedCage != null && cages.any((c) => c.id == _selectedCage!.id) 
              ? cages.firstWhere((c) => c.id == _selectedCage!.id) 
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: cages.isEmpty ? 'Chưa có chuồng' : 'Chọn chuồng',
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.home, size: 18),
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
          initialValue: selected,
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

  // Tồn kho = Nhập kho (0) - Xuất kho (1)
  Widget _buildInventoryDisplayField() {
    final pigType = _pigTypeController.text.trim();
    if (pigType.isEmpty) {
      return _buildInventoryContainer(0);
    }
    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest2(
        _invoiceRepo.watchInvoices(type: 0), // Nhập kho (hàng thừa từ chợ) (+)
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
            if ((item.pigType ?? '').trim() == pigType) {
              available += item.quantity;
            }
          }
        }
        
        // - Xuất kho (Type 1)
        for (final inv in exportBarn) {
          for (final item in inv.details) {
            if ((item.pigType ?? '').trim() == pigType) {
              available -= item.quantity;
            }
          }
        }
        
        return _buildInventoryContainer(available);
      },
    );
  }

  Widget _buildInventoryContainer(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        '$qty con',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.green[700],
        ),
      ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.brown),
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
              backgroundColor: canSave
                  ? (_isEditMode ? Colors.brown : Colors.brown)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveInvoice() {
    final weight =
        double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;
    final hasWeight = weight > 0;

    return _selectedPartner != null &&
        _pigTypeController.text.isNotEmpty &&
        hasWeight;
  }

  void _saveInvoice(BuildContext context) async {
    // Capture scaffold messenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final weighingBloc = context.read<WeighingBloc>();
    
    final weight =
        double.tryParse(_scaleInputController.text.replaceAll(',', '.')) ?? 0;

    if (weight <= 0) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập số cân!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _totalWeight = weight;
    });

    if (!_canSaveInvoice()) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng điền đầy đủ thông tin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Kiểm tra tồn kho: Tồn kho = Type 0 (Nhập kho) - Type 1 (Xuất kho)
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final pigType = _pigTypeController.text.trim();

    try {
      final importInvoices = await _invoiceRepo.watchInvoices(type: 0).first;
      final exportInvoices = await _invoiceRepo.watchInvoices(type: 1).first;

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
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                '❌ Không đủ tồn kho! Chỉ còn $available con $pigType trong kho.'),
            backgroundColor: Colors.brown,
          ),
        );
        return;
      }

      if (!mounted) return;
      
      // Thêm invoice item
      weighingBloc.add(
            WeighingItemAdded(
              weight: _totalWeight,
              quantity: quantity,
              batchNumber: _batchNumberController.text.isNotEmpty
                  ? _batchNumberController.text
                  : null,
              pigType: pigType,
            ),
          );

      final reason = _farmNameController.text.trim();
      final cage = _cageController.text.trim();
      final otherNote = _noteController.text.trim();

      List<String> noteParts = [];
      if (reason.isNotEmpty) noteParts.add('Lý do: $reason');
      if (cage.isNotEmpty) noteParts.add('Chuồng: $cage');
      if (otherNote.isNotEmpty) noteParts.add(otherNote);
      final note = noteParts.join(' | ');

      // Chỉ lưu thông tin cơ bản - không tính tiền
      weighingBloc.add(
            WeighingInvoiceUpdated(
              partnerId: _selectedPartner!.id,
              partnerName: _selectedPartner!.name,
              cageId: _selectedCage?.id,
              pricePerKg: 0, // Không tính giá
              deduction: 0,
              discount: 0,
              note: note,
              finalAmount: 0, // Không tính tiền
            ),
          );

      weighingBloc.add(const WeighingSaved());
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.brown,
          ),
        );
      }
    }
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
    _paymentAmountController.clear();
    _cageController.clear();
    setState(() {
      _selectedPartner = null;
      _selectedCage = null;
      _selectedInvoice = null;
      _isEditMode = false;
      _totalWeight = 0;
    });
    context.read<WeighingBloc>().add(const WeighingStarted(1));
    _scaleInputFocus.requestFocus();
  }

  void _loadInvoiceToForm(InvoiceEntity invoice) {
    String reason = '';
    String cage = '';
    String otherNote = '';

    if (invoice.note != null && invoice.note!.isNotEmpty) {
      final parts = invoice.note!.split(' | ');
      for (final part in parts) {
        if (part.startsWith('Lý do: ')) {
          reason = part.replaceFirst('Lý do: ', '');
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

    final weight = invoice.totalWeight;

    setState(() {
      _selectedInvoice = invoice;
      _isEditMode = true;

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

      _farmNameController.text = reason;
      _cageController.text = cage;
      _noteController.text = otherNote;
      _pigTypeController.text = pigType;
      _batchNumberController.text = batchNumber;
      _quantityController.text = '${invoice.totalQuantity}';
      _priceController.text =
          invoice.pricePerKg > 0 ? invoice.pricePerKg.toStringAsFixed(0) : '';

      _scaleInputController.text = weight.toStringAsFixed(1);
      _totalWeight = weight;
    });
  }

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

      final note = _farmNameController.text.isNotEmpty
          ? 'Lý do: ${_farmNameController.text}${_noteController.text.isNotEmpty ? ' | ${_noteController.text}' : ''}'
          : _noteController.text;

      final updatedInvoice = _selectedInvoice!.copyWith(
        partnerId: _selectedPartner!.id,
        partnerName: _selectedPartner!.name,
        totalWeight: _totalWeight,
        totalQuantity: quantity,
        pricePerKg: _pricePerKg,
        finalAmount: _subtotal,
        note: note,
      );

      await _invoiceRepo.updateInvoice(updatedInvoice);

      if (_selectedInvoice!.details.isNotEmpty) {
        final updatedItem = _selectedInvoice!.details.first.copyWith(
          pigType: pigType,
          batchNumber: _batchNumberController.text.isNotEmpty
              ? _batchNumberController.text
              : null,
          weight: _totalWeight,
          quantity: quantity,
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
            backgroundColor: Colors.brown,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteInvoice(
      BuildContext context, InvoiceEntity invoice) async {
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
      stream: _invoiceRepo.watchInvoices(type: 1), // Type 1 = Xuất kho
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var invoices = snapshot.data!;
        if (invoices.isEmpty) {
          return const Center(child: Text('Chưa có phiếu xuất kho nào'));
        }

        return Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.brown[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU XUẤT KHO ĐÃ LƯU (${invoices.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.brown),
                    ),
                  ],
                ),
              ),
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
                        DataColumn(label: Text('Thời gian')),
                        DataColumn(label: Text('Tên NCC')),
                        DataColumn(label: Text('Lý do')),
                        DataColumn(label: Text('Chuồng')),
                        DataColumn(label: Text('Loại heo')),
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('TL (kg)')),
                        DataColumn(label: Text('Đơn giá')),
                        DataColumn(label: Text('Thành tiền')),
                      ],
                      rows: List.generate(invoices.length, (idx) {
                        final inv = invoices[idx];
                        final dateFormat = DateFormat('dd/MM HH:mm');

                        String reason = '';
                        String cage = '';
                        if (inv.note != null && inv.note!.isNotEmpty) {
                          final parts = inv.note!.split(' | ');
                          for (final part in parts) {
                            if (part.startsWith('Lý do: ')) {
                              reason = part.replaceFirst('Lý do: ', '');
                            } else if (part.startsWith('Chuồng: ')) {
                              cage = part.replaceFirst('Chuồng: ', '');
                            }
                          }
                        }

                        final pigType = inv.details.isNotEmpty
                            ? (inv.details.first.pigType ?? '-')
                            : '-';

                        final isSelected = _selectedInvoice?.id == inv.id;

                        return DataRow(
                          selected: isSelected,
                          color:
                              WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.brown.shade100;
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
                              child: Text(inv.partnerName ?? 'NCC',
                                  overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(SizedBox(
                              width: 80,
                              child:
                                  Text(reason, overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(SizedBox(
                              width: 50,
                              child:
                                  Text(cage, overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(Text(pigType)),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text('${inv.totalQuantity}'))),
                            DataCell(Align(
                              alignment: Alignment.centerRight,
                              child:
                                  Text(_numberFormat.format(inv.totalWeight)),
                            )),
                            DataCell(Align(
                              alignment: Alignment.centerRight,
                              child:
                                  Text(_currencyFormat.format(inv.pricePerKg)),
                            )),
                            DataCell(Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _currencyFormat
                                    .format(inv.totalWeight * inv.pricePerKg),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
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
}
