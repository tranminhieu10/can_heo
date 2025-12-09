import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../../core/services/scale_service.dart';
import '../../../../domain/entities/partner.dart';
import '../../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';
import '../../../../domain/entities/pig_type.dart';
import '../../../../domain/repositories/i_pigtype_repository.dart';
import '../pig_types/pig_types_screen.dart';
import '../history/invoice_detail_screen.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';

class ImportBarnScreen extends StatelessWidget {
  const ImportBarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(0))),
        BlocProvider(
            create: (_) => sl<PartnerBloc>()..add(const LoadPartners(true))),
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
  final TextEditingController _scaleInputController = TextEditingController();
  final TextEditingController _partnerController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _truckCostController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _searchPartnerController = TextEditingController();
  final TextEditingController _searchBatchController = TextEditingController();
  final TextEditingController _searchPigTypeController = TextEditingController();
  final TextEditingController _searchQuantityController = TextEditingController();

  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  Timer? _dateTimer;

  PartnerEntity? _selectedPartner;
  String _importType = 'supplier';
  
  // Track which search columns are visible
  final Set<String> _activeSearchColumns = {};

  @override
  void initState() {
    super.initState();
    _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scaleInputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scaleInputController.dispose();
    _partnerController.dispose();
    _dateTimeController.dispose();
    _dateTimer?.cancel();
    _batchNumberController.dispose();
    _pigTypeController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _truckCostController.dispose();
    _quantityController.dispose();
    _searchPartnerController.dispose();
    _searchBatchController.dispose();
    _searchPigTypeController.dispose();
    _searchQuantityController.dispose();
    _scaleInputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f4): () => _saveInvoice(context),
        const SingleActivator(LogicalKeyboardKey.f1): () => _addFromScale(context),
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
                  duration: Duration(seconds: 5),
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
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScaleSection(context),
                  const SizedBox(height: 16),
                  // Row: Invoice Details (left) + Payment Grid (right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildInvoiceDetailsSection(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildPaymentGrid(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSavedInvoicesGrid(context),
                  const SizedBox(height: 20),
                  const Text(
                    "Phím tắt: [Enter] Thêm cân | [F1] Lấy từ cân | [F4] Lưu phiếu | [F2] Tare",
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
    _quantityController.text = '1';
    _priceController.clear();
    _truckCostController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    setState(() {
      _selectedPartner = null;
      _importType = 'supplier';
    });
    context.read<WeighingBloc>().add(const WeighingStarted(0));
    _scaleInputFocus.requestFocus();
  }

  void _saveInvoice(BuildContext context) {
    if (context.read<WeighingBloc>().state.items.isNotEmpty) {
      context.read<WeighingBloc>().add(const WeighingSaved());
    }
  }

  void _addFromScale(BuildContext context) {
    final state = context.read<WeighingBloc>().state;
    if (state.isScaleConnected && state.scaleWeight > 0) {
      _addWeightFromScale(context, state.scaleWeight);
    }
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRỌNG LƯỢNG (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            connected ? _numberFormat.format(weight) : 'Mất kết nối',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: connected ? Colors.orange[800] : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _scaleInputController,
                        focusNode: _scaleInputFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: (_) => _addWeightManual(context),
                        decoration: const InputDecoration(
                          labelText: 'Nhập tay (test)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: connected ? () => sl<IScaleService>().tare() : null,
                      child: const Text('CHỐT CÂN (F2)'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: connected && weight > 0 ? () => _addFromScale(context) : null,
                      child: const Text('LẤY SỐ (F1)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Title + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'THÔNG TIN PHIẾU NHẬP KHO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Import Type (full width)
                DropdownButtonFormField<String>(
                  value: _importType,
                  decoration: const InputDecoration(
                    labelText: 'Loại nhập',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'supplier', child: Text('Nhập từ nhà cung cấp (MUA)')),
                    DropdownMenuItem(value: 'returned', child: Text('Hoàn hàng từ chợ (TRẢ)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _importType = value;
                        _selectedPartner = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Row 2: Partner (full width)
                _buildPartnerSelector(context),
                const SizedBox(height: 12),
                // Row 3: Pig Type + Batch Number
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: StreamBuilder<List<PigTypeEntity>>(
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
                            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                _pigTypeController.text = v.name;
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _batchNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Số lô',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 4: Quantity + Inventory + Price + Truck Cost
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'SL con',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildInventoryBox(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateInvoiceCalculations(context),
                        decoration: const InputDecoration(
                          labelText: 'Đơn giá (đ/kg)',
                          suffixText: 'đ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _truckCostController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _updateInvoiceCalculations(context),
                        decoration: const InputDecoration(
                          labelText: 'Chi phí khác (đ)',
                          suffixText: 'đ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Row 5: Note (full width, multiline)
                TextField(
                  controller: _noteController,
                  onChanged: (val) {
                    context.read<WeighingBloc>().add(WeighingInvoiceUpdated(note: val));
                  },
                  minLines: 1,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentGrid(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange[100],
            child: const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'DANH SÁCH CÂN NHẬP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                ),
              ],
            ),
          ),
          BlocBuilder<WeighingBloc, WeighingState>(
            builder: (context, state) {
              if (state.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('Chưa có mã cân nhập', style: TextStyle(color: Colors.grey[600])),
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Thứ tự')),
                    DataColumn(label: Text('Số lô')),
                    DataColumn(label: Text('Loại heo')),
                    DataColumn(label: Text('Khối lượng (kg)')),
                    DataColumn(label: Text('Số con')),
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Hành động')),
                  ],
                  rows: state.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(item.batchNumber ?? '-')),
                        DataCell(Text(item.pigType ?? '-')),
                        DataCell(Text(_numberFormat.format(item.weight))),
                        DataCell(Text('${item.quantity}')),
                        DataCell(Text(DateFormat('HH:mm:ss').format(item.time))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              context.read<WeighingBloc>().add(WeighingItemRemoved(item.id));
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryBox(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 0), // Import invoices
      builder: (context, importSnap) {
        return StreamBuilder<List<InvoiceEntity>>(
          stream: sl<IInvoiceRepository>().watchInvoices(type: 2), // Export invoices
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

            return Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Tồn kho', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      '$availableQty',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 0),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Tổng Nhập: 0.0 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      Text('Số lượng: 0 con', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  const Text('₫0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.orange)),
                ],
              ),
            ),
          );
        }

        var invoices = snapshot.data!;
        if (invoices.isEmpty) {
          return Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Tổng Nhập: 0.0 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      Text('Số lượng: 0 con', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  const Text('₫0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.orange)),
                ],
              ),
            ),
          );
        }

        // Filter invoices
        invoices = invoices.where((inv) {
          final partner = _searchPartnerController.text.trim().toLowerCase();
          final batch = _searchBatchController.text.trim().toLowerCase();
          final pigType = _searchPigTypeController.text.trim().toLowerCase();
          final quantity = _searchQuantityController.text.trim();

          final invPartner = (inv.partnerName ?? 'Nhà cung cấp').toLowerCase();
          final invBatch = inv.details.isNotEmpty ? (inv.details.first.batchNumber ?? '').toLowerCase() : '';
          final invPigType = inv.details.isNotEmpty ? (inv.details.first.pigType ?? '').toLowerCase() : '';
          final invQuantity = '${inv.totalQuantity}';

          bool matches = true;
          if (partner.isNotEmpty && !invPartner.contains(partner)) matches = false;
          if (batch.isNotEmpty && !invBatch.contains(batch)) matches = false;
          if (pigType.isNotEmpty && !invPigType.contains(pigType)) matches = false;
          if (quantity.isNotEmpty && !invQuantity.contains(quantity)) matches = false;
          return matches;
        }).toList();

        return Card(
          elevation: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Text(
                      'PHIẾU NHẬP ĐÃ LƯU (${invoices.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                    ),
                    const Spacer(),
                    if (_activeSearchColumns.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeSearchColumns.clear();
                            _searchPartnerController.clear();
                            _searchBatchController.clear();
                            _searchPigTypeController.clear();
                            _searchQuantityController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Xóa lọc', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              // Search row - only show if any search column is active
              if (_activeSearchColumns.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      if (_activeSearchColumns.contains('partner'))
                        Expanded(
                          child: TextField(
                            controller: _searchPartnerController,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tìm nhà cung cấp...',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(() {
                                  _activeSearchColumns.remove('partner');
                                  _searchPartnerController.clear();
                                }),
                              ),
                            ),
                          ),
                        ),
                      if (_activeSearchColumns.contains('batch')) ...[
                        if (_activeSearchColumns.contains('partner')) const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchBatchController,
                            autofocus: _activeSearchColumns.length == 1,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tìm số lô...',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(() {
                                  _activeSearchColumns.remove('batch');
                                  _searchBatchController.clear();
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_activeSearchColumns.contains('pigType')) ...[
                        if (_activeSearchColumns.isNotEmpty && !_activeSearchColumns.contains('pigType') == false) const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchPigTypeController,
                            autofocus: _activeSearchColumns.length == 1,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Tìm loại heo...',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(() {
                                  _activeSearchColumns.remove('pigType');
                                  _searchPigTypeController.clear();
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_activeSearchColumns.contains('quantity')) ...[
                        if (_activeSearchColumns.length > 1) const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _searchQuantityController,
                            keyboardType: TextInputType.number,
                            autofocus: _activeSearchColumns.length == 1,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'SL...',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(() {
                                  _activeSearchColumns.remove('quantity');
                                  _searchQuantityController.clear();
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  dataRowMaxHeight: 52,
                  headingRowHeight: 40,
                  columns: [
                    const DataColumn(label: Text('STT')),
                    const DataColumn(label: Text('Thời gian')),
                    DataColumn(
                      label: InkWell(
                        onTap: () => setState(() {
                          if (_activeSearchColumns.contains('partner')) {
                            _activeSearchColumns.remove('partner');
                            _searchPartnerController.clear();
                          } else {
                            _activeSearchColumns.add('partner');
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nhà cung cấp'),
                            const SizedBox(width: 4),
                            Icon(
                              _activeSearchColumns.contains('partner') ? Icons.search_off : Icons.search,
                              size: 16,
                              color: _activeSearchColumns.contains('partner') ? Colors.orange : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: InkWell(
                        onTap: () => setState(() {
                          if (_activeSearchColumns.contains('batch')) {
                            _activeSearchColumns.remove('batch');
                            _searchBatchController.clear();
                          } else {
                            _activeSearchColumns.add('batch');
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Số lô'),
                            const SizedBox(width: 4),
                            Icon(
                              _activeSearchColumns.contains('batch') ? Icons.search_off : Icons.search,
                              size: 16,
                              color: _activeSearchColumns.contains('batch') ? Colors.orange : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: InkWell(
                        onTap: () => setState(() {
                          if (_activeSearchColumns.contains('pigType')) {
                            _activeSearchColumns.remove('pigType');
                            _searchPigTypeController.clear();
                          } else {
                            _activeSearchColumns.add('pigType');
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Loại heo'),
                            const SizedBox(width: 4),
                            Icon(
                              _activeSearchColumns.contains('pigType') ? Icons.search_off : Icons.search,
                              size: 16,
                              color: _activeSearchColumns.contains('pigType') ? Colors.orange : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: InkWell(
                        onTap: () => setState(() {
                          if (_activeSearchColumns.contains('quantity')) {
                            _activeSearchColumns.remove('quantity');
                            _searchQuantityController.clear();
                          } else {
                            _activeSearchColumns.add('quantity');
                          }
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('SL'),
                            const SizedBox(width: 4),
                            Icon(
                              _activeSearchColumns.contains('quantity') ? Icons.search_off : Icons.search,
                              size: 16,
                              color: _activeSearchColumns.contains('quantity') ? Colors.orange : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const DataColumn(label: Text('Tổng KL')),
                    const DataColumn(label: Text('Thành tiền')),
                    const DataColumn(label: Text('Ghi chú')),
                    const DataColumn(label: Text('')),
                  ],
                  rows: List.generate(invoices.length, (idx) {
                    final inv = invoices[idx];
                    final batch = inv.details.isNotEmpty ? (inv.details.first.batchNumber ?? '-') : '-';
                    final pigType = inv.details.isNotEmpty ? (inv.details.first.pigType ?? '-') : '-';
                    return DataRow(cells: [
                      DataCell(Center(child: Text('${idx + 1}'))),
                      DataCell(Text(DateFormat('dd/MM HH:mm').format(inv.createdDate), style: const TextStyle(color: Colors.black54, fontSize: 12))),
                      DataCell(SizedBox(width: 160, child: Text(inv.partnerName ?? 'Nhà cung cấp', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)))),
                      DataCell(Text(batch, style: const TextStyle(fontSize: 13))),
                      DataCell(Text(pigType, style: const TextStyle(fontSize: 13))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text('${inv.totalQuantity}', style: const TextStyle(fontSize: 13)))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text('${_numberFormat.format(inv.totalWeight)} kg', style: const TextStyle(fontSize: 13)))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text(_currencyFormat.format(inv.finalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)))),
                      DataCell(SizedBox(width: 160, child: Text(inv.note ?? '-', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 18),
                            tooltip: 'Xem',
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            tooltip: 'Xóa',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xóa phiếu'),
                                  content: const Text('Bạn có chắc muốn xóa phiếu này?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('HỦY')),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('XÓA')),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await sl<IInvoiceRepository>().deleteInvoice(inv.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu')));
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnerSelector(BuildContext context) {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, partnerState) {
        final isSupplier = _importType == 'supplier';
        final labelText = isSupplier ? 'Nhà cung cấp (Trại)' : 'Khách hàng (Cửa hàng)';
        final hintText = isSupplier ? 'Chọn nhà cung cấp...' : 'Chọn khách hàng...';

        return DropdownButtonFormField<PartnerEntity>(
          value: _selectedPartner,
          hint: Text(hintText),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
            helperText: isSupplier ? 'Chọn trại/nhà cung cấp để mua heo' : 'Chọn khách hàng để nhận hàng hoàn',
          ),
          items: partnerState.partners.map((partner) {
            return DropdownMenuItem(value: partner, child: Text(partner.name));
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedPartner = newValue);
            if (newValue != null) {
              _partnerController.text = newValue.name;
              context.read<WeighingBloc>().add(
                WeighingInvoiceUpdated(partnerId: newValue.id, partnerName: newValue.name),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: FilledButton.icon(
            onPressed: state.items.isEmpty ? null : () => _saveInvoice(context),
            icon: const Icon(Icons.save),
            label: const Text('LƯU (F4)'),
          ),
        );
      },
    );
  }

  void _addWeightManual(BuildContext context) {
    final text = _scaleInputController.text;
    if (text.isEmpty) return;
    final weight = double.tryParse(text);
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (weight != null && weight > 0) {
      context.read<WeighingBloc>().add(WeighingItemAdded(
        weight: weight,
        quantity: quantity,
        batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
        pigType: _pigTypeController.text.isNotEmpty ? _pigTypeController.text : null,
      ));
      _scaleInputController.clear();
      _scaleInputFocus.requestFocus();
    }
  }

  void _addWeightFromScale(BuildContext context, double weight) {
    if (weight > 0) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      context.read<WeighingBloc>().add(WeighingItemAdded(
        weight: weight,
        quantity: quantity,
        batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
        pigType: _pigTypeController.text.isNotEmpty ? _pigTypeController.text : null,
      ));
      _scaleInputFocus.requestFocus();
    }
  }

  void _updateInvoiceCalculations(BuildContext context) {
    double price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    double cost = double.tryParse(_truckCostController.text.replaceAll(',', '')) ?? 0;
    context.read<WeighingBloc>().add(WeighingInvoiceUpdated(pricePerKg: price, deduction: cost));
  }
}
