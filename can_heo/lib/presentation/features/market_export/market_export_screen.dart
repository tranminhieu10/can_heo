import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../../../core/services/scale_service.dart';
import '../../../domain/entities/partner.dart';
import '../../../domain/entities/pig_type.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../pig_types/pig_types_screen.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
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
  // Controllers cho đầu cân
  final TextEditingController _scaleInputController = TextEditingController();
  
  // Controllers cho thông tin phiếu
  final TextEditingController _partnerController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Controllers cho tính toán
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _truckCostController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  
  // Controllers cho tìm kiếm phiếu đã lưu
  final TextEditingController _searchPartnerController = TextEditingController();
  final TextEditingController _searchBatchController = TextEditingController();
  final TextEditingController _searchPigTypeController = TextEditingController();
  final TextEditingController _searchQuantityController = TextEditingController();
  
  final FocusNode _scaleInputFocus = FocusNode();
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  Timer? _dateTimer;

  PartnerEntity? _selectedPartner;

  @override
  void initState() {
    super.initState();
    _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    // Update the displayed time every second to act like a real-time clock
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
              final invoiceId = state.currentInvoice?.id;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Đã lưu phiếu xuất chợ!'),
                  backgroundColor: Colors.green,
                  action: invoiceId == null
                      ? null
                      : SnackBarAction(
                          label: 'XEM NGAY',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(invoiceId: invoiceId),
                              ),
                            );
                          },
                        ),
                ),
              );
              _resetForm();
            } else if (state.status == WeighingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Lỗi không xác định'),
                  backgroundColor: Colors.red,
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PigTypesScreen())),
                ),
                _buildSaveButton(context),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1. PHẦN TRỌNG LƯỢNG ĐẦU CÂN
                  _buildScaleSection(context),
                  const SizedBox(height: 16),
                  
                  // 2. PHẦN THÔNG TIN CHI TIẾT
                  _buildInvoiceDetailsSection(context),
                  const SizedBox(height: 16),
                  
                  // 3. DATAGRID THANH TOÁN (Thanh toán trước khi lưu)
                  _buildPaymentGrid(context),
                  const SizedBox(height: 16),

                  // 4. DANH SÁCH PHIẾU ĐÃ LƯU (Lịch sử/biên lai)
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

  // === 1. PHẦN TRỌNG LƯỢNG ĐẦU CÂN ===
  Widget _buildScaleSection(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final weight = state.scaleWeight;
        final connected = state.isScaleConnected;

        return Card(
          color: Colors.blue[50],
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
                          const Text('TRỌNG LƯỢNG (kg)', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            connected ? '${_numberFormat.format(weight)}' : 'Mất kết nối',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: connected ? Colors.blue[800] : Colors.red,
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

  // === 2. PHẦN THÔNG TIN CHI TIẾT ===
  Widget _buildInvoiceDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('THÔNG TIN PHIẾU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            
            // Khách hàng
            _buildPartnerSelector(context),
            const SizedBox(height: 12),
            
            // Ngày giờ + Số lô + Loại heo
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dateTimeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian (dd/MM/yyyy HH:mm)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _batchNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Số lô',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: StreamBuilder<List<PigTypeEntity>>(
                    stream: sl<IPigTypeRepository>().watchPigTypes(),
                    builder: (context, snap) {
                      final types = snap.data ?? [];
                      final PigTypeEntity? selected = types.isEmpty
                          ? null
                          : types.firstWhere((t) => t.name == _pigTypeController.text, orElse: () => types.first);

                      return DropdownButtonFormField<PigTypeEntity?>(
                        value: selected,
                        decoration: const InputDecoration(labelText: 'Loại heo', border: OutlineInputBorder()),
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
              ],
            ),
            const SizedBox(height: 12),
            
            // Ghi chú phiếu
            TextField(
              controller: _noteController,
              onChanged: (val) {
                context.read<WeighingBloc>().add(WeighingInvoiceUpdated(note: val));
              },
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Giá tiền + Cước xe + Số lượng
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updateInvoiceCalculations(context),
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá (đ/kg)',
                      border: OutlineInputBorder(),
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
                      labelText: 'Cước xe (đ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'SL con',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    // Change: instead of immediately adding a weighing item,
                    // the button will increase the SL (số con) by 1.
                    final current = int.tryParse(_quantityController.text) ?? 1;
                    final updated = current + 1;
                    _quantityController.text = '$updated';
                    setState(() {});
                  },
                  child: const Text('THÊM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === 3. DATAGRID CHI TIẾT CÂN ===
  Widget _buildWeighingDetailsGrid(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('CHI TIẾT CÂN (${state.items.length} lần)', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('STT')),
                    DataColumn(label: Text('Lần cân')),
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Số lô')),
                    DataColumn(label: Text('KL (kg)')),
                    DataColumn(label: Text('SL con')),
                    DataColumn(label: Text('Đơn giá (đ)')),
                    DataColumn(label: Text('Thành tiền (đ)')),
                    DataColumn(label: Text('Hành động')),
                  ],
                  rows: List.generate(state.items.length, (idx) {
                    final item = state.items[idx];
                    final invoice = state.currentInvoice;
                    final price = invoice != null ? 
                        (double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0) : 0;
                    final totalAmount = item.weight * price;

                    return DataRow(
                      cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(Text('${item.sequence}')),
                        DataCell(Text(DateFormat('HH:mm:ss').format(item.time))),
                        DataCell(Text('-')), // TODO: item.batchNumber khi database regenerate
                        DataCell(Text('${_numberFormat.format(item.weight)}')),
                        DataCell(Text('${item.quantity}')),
                        DataCell(Text('${_numberFormat.format(price)}')),
                        DataCell(Text('${_currencyFormat.format(totalAmount)}')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => context.read<WeighingBloc>().add(WeighingItemRemoved(item.id)),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === 3.5. DANH SÁCH PHIẾU ĐÃ LƯU (Xuất chợ) ===
  Widget _buildSavedInvoicesGrid(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var invoices = snapshot.data!;
        if (invoices.isEmpty) return const SizedBox.shrink();

        // Áp dụng filter theo các trường tìm kiếm
        invoices = invoices.where((inv) {
          final partner = _searchPartnerController.text.trim().toLowerCase();
          final batch = _searchBatchController.text.trim().toLowerCase();
          final pigType = _searchPigTypeController.text.trim().toLowerCase();
          final quantity = _searchQuantityController.text.trim();

          final invPartner = (inv.partnerName ?? 'Khách lẻ').toLowerCase();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PHIẾU ĐÃ LƯU (${invoices.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    // Search filters
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchPartnerController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Tìm khách hàng',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchBatchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Tìm số lô',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchPigTypeController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Tìm loại heo',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _searchQuantityController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Tìm SL',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.search, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  dataRowHeight: 52,
                  headingRowHeight: 40,
                  columns: const [
                    DataColumn(label: Text('STT')),
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Số lô')),
                    DataColumn(label: Text('Loại heo')),
                    DataColumn(label: Text('SL')),
                    DataColumn(label: Text('Tổng KL')),
                    DataColumn(label: Text('Thành tiền')),
                    DataColumn(label: Text('Ghi chú')),
                    DataColumn(label: Text('')),
                  ],
                  rows: List.generate(invoices.length, (idx) {
                    final inv = invoices[idx];
                    final batch = inv.details.isNotEmpty ? (inv.details.first.batchNumber ?? '-') : '-';
                    final pigType = inv.details.isNotEmpty ? (inv.details.first.pigType ?? '-') : '-';
                    return DataRow(cells: [
                      DataCell(Center(child: Text('${idx + 1}'))),
                      DataCell(Text(DateFormat('dd/MM HH:mm').format(inv.createdDate), style: TextStyle(color: Colors.black54, fontSize: 12))),
                      DataCell(SizedBox(width: 160, child: Text(inv.partnerName ?? 'Khách lẻ', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)))),
                      DataCell(Text(batch, style: TextStyle(fontSize: 13))),
                      DataCell(Text(pigType, style: TextStyle(fontSize: 13))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text('${inv.totalQuantity}', style: TextStyle(fontSize: 13)))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text('${_numberFormat.format(inv.totalWeight)} kg', style: TextStyle(fontSize: 13)))),
                      DataCell(Align(alignment: Alignment.centerRight, child: Text(_currencyFormat.format(inv.finalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)))),
                      DataCell(SizedBox(width: 160, child: Text(inv.note ?? '-', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black87)))),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.visibility, size: 18), tooltip: 'Xem', onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id))); }),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red, size: 18), tooltip: 'Xóa', onPressed: () async {
                          final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                            title: Text('Xóa phiếu'),
                            content: Text('Bạn có chắc muốn xóa phiếu này?'),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('HỦY')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('XÓA'))],
                          ));
                          if (confirmed == true) {
                            await sl<IInvoiceRepository>().deleteInvoice(inv.id);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu')));
                          }
                        }),
                      ])),
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

  // === 4. DATAGRID THANH TOÁN ===
  Widget _buildPaymentGrid(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final invoice = state.currentInvoice;
        if (invoice == null || state.items.isEmpty) return const SizedBox.shrink();

        // Dữ liệu thanh toán (mẫu)
        final payments = [
          {
            'stt': 1,
            'batchNumber': _batchNumberController.text.isNotEmpty ? _batchNumberController.text : '-',
            'partner': _selectedPartner?.name ?? 'Chưa chọn',
            'amount': invoice.finalAmount,
            'type': 'Chuyển khoản',
            'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          }
        ];

        return Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('THANH TOÁN (${payments.length})', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('STT')),
                    DataColumn(label: Text('Số lô')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Số tiền (đ)')),
                    DataColumn(label: Text('Loại hình')),
                    DataColumn(label: Text('Thời gian trả')),
                  ],
                  rows: List.generate(payments.length, (idx) {
                    final p = payments[idx];
                    return DataRow(
                      cells: [
                        DataCell(Text('${p['stt']}')),
                        DataCell(Text('${p['batchNumber']}')),
                        DataCell(Text('${p['partner']}')),
                        DataCell(Text('${_currencyFormat.format(p['amount'])}')),
                        DataCell(Text('${p['type']}')),
                        DataCell(Text('${p['date']}')),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === HELPERS & LOGIC ===

  Widget _buildPartnerSelector(BuildContext context) {
    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        final partners = state.partners;
        final safeValue = (partners.contains(_selectedPartner)) ? _selectedPartner : null;

        return DropdownButtonFormField<PartnerEntity>(
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Khách hàng', border: OutlineInputBorder()),
          value: safeValue,
          items: partners.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
          onChanged: (value) {
            setState(() => _selectedPartner = value);
            if (value != null) {
              context.read<WeighingBloc>().add(
                WeighingInvoiceUpdated(partnerId: value.id, partnerName: value.name),
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
        final enabled = state.items.isNotEmpty && state.status != WeighingStatus.loading;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: FilledButton.icon(
            onPressed: enabled ? () => _saveInvoice(context) : null,
            icon: const Icon(Icons.save),
            label: const Text('LƯU (F4)'),
          ),
        );
      },
    );
  }

  void _addWeightManual(BuildContext context) {
    final raw = _scaleInputController.text.trim();
    if (raw.isEmpty) return;

    final weight = double.tryParse(raw.replaceAll(',', '.'));
    if (weight != null && weight > 0) {
      final quantity = _getQuantity();

      context.read<WeighingBloc>().add(
        WeighingItemAdded(
          weight: weight,
          quantity: quantity,
          batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
          pigType: _pigTypeController.text.isNotEmpty ? _pigTypeController.text : null,
        ),
      );

      _scaleInputController.clear();
      _scaleInputFocus.requestFocus();
    }
  }

  void _addFromScale(BuildContext context) {
    final state = context.read<WeighingBloc>().state;
    if (state.isScaleConnected && state.scaleWeight > 0) {
      final quantity = _getQuantity();

      context.read<WeighingBloc>().add(
        WeighingItemAdded(
          weight: state.scaleWeight,
          quantity: quantity,
          batchNumber: _batchNumberController.text.isNotEmpty ? _batchNumberController.text : null,
          pigType: _pigTypeController.text.isNotEmpty ? _pigTypeController.text : null,
        ),
      );

      _scaleInputFocus.requestFocus();
    }
  }

  int _getQuantity() {
    final raw = _quantityController.text.trim();
    return int.tryParse(raw) ?? 1;
  }

  void _updateInvoiceCalculations(BuildContext context) {
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    final truck = double.tryParse(_truckCostController.text.replaceAll(',', '')) ?? 0;

    context.read<WeighingBloc>().add(
      WeighingInvoiceUpdated(pricePerKg: price, truckCost: truck),
    );
  }

  void _saveInvoice(BuildContext context) {
    final state = context.read<WeighingBloc>().state;
    if (state.items.isNotEmpty && state.status != WeighingStatus.loading) {
      context.read<WeighingBloc>().add(const WeighingSaved());
    }
  }

  void _resetForm() {
    _scaleInputController.clear();
    _partnerController.clear();
    _batchNumberController.clear();
    _noteController.clear();
    _pigTypeController.clear();
    _priceController.clear();
    _truckCostController.clear();
    _quantityController.text = '1';
    _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    setState(() {
      _selectedPartner = null;
    });

    context.read<WeighingBloc>().add(const WeighingStarted(2));
    _scaleInputFocus.requestFocus();
  }
}
