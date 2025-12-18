import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/services/excel_export_service.dart';
import '../../../injection_container.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import 'bloc/invoice_history_bloc.dart';
import 'bloc/invoice_history_event.dart';
import 'bloc/invoice_history_state.dart';
import 'invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatelessWidget {
  final int invoiceType;

  const InvoiceHistoryScreen({super.key, required this.invoiceType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvoiceHistoryBloc>()..add(LoadInvoices(invoiceType)),
      child: const _InvoiceHistoryView(),
    );
  }
}

class _InvoiceHistoryView extends StatefulWidget {
  const _InvoiceHistoryView();

  @override
  State<_InvoiceHistoryView> createState() => _InvoiceHistoryViewState();
}

class _InvoiceHistoryViewState extends State<_InvoiceHistoryView> {
  final _searchController = TextEditingController();
  final _pigTypeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _minWeightController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  int? _daysFilter; // null = tất cả
  Timer? _debounce;
  bool _showAdvancedFilters = false;
  int _selectedType = 2; // Mặc định Xuất chợ

  @override
  void initState() {
    super.initState();
    // Lấy type từ widget ban đầu
    _selectedType = (context.read<InvoiceHistoryBloc>().state as dynamic)
            .toString()
            .contains('type')
        ? context.read<InvoiceHistoryBloc>().state.hashCode
        : 2;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pigTypeController.dispose();
    _batchNumberController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Áp dụng bộ lọc ngay lập tức (không debounce)
  void _applyFilter() {
    context.read<InvoiceHistoryBloc>().add(
          FilterInvoices(
            keyword: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            daysFilter: _daysFilter,
            pigType: _pigTypeController.text.trim().isEmpty
                ? null
                : _pigTypeController.text.trim(),
            batchNumber: _batchNumberController.text.trim().isEmpty
                ? null
                : _batchNumberController.text.trim(),
            minWeight: _minWeightController.text.trim().isEmpty
                ? null
                : double.tryParse(_minWeightController.text.trim()),
            maxWeight: _maxWeightController.text.trim().isEmpty
                ? null
                : double.tryParse(_maxWeightController.text.trim()),
            minAmount: _minAmountController.text.trim().isEmpty
                ? null
                : double.tryParse(_minAmountController.text.trim()),
            maxAmount: _maxAmountController.text.trim().isEmpty
                ? null
                : double.tryParse(_maxAmountController.text.trim()),
          ),
        );
  }

  // Gửi event lọc xuống Bloc với debounce (tự động)
  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilter();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _pigTypeController.clear();
      _batchNumberController.clear();
      _minWeightController.clear();
      _maxWeightController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _daysFilter = null;
    });
    _applyFilter(); // Áp dụng ngay sau khi xóa
  }

  Future<void> _exportExcel(BuildContext context) async {
    final state = context.read<InvoiceHistoryBloc>().state;

    if (state.invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất')),
      );
      return;
    }

    try {
      await ExcelExportService.exportInvoicesToExcel(state.invoices);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xuất Excel')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử phiếu'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc nâng cao',
            icon: Icon(_showAdvancedFilters
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
          ),
          IconButton(
            tooltip: 'Xóa tất cả bộ lọc',
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllFilters,
          ),
          IconButton(
            tooltip: 'Xuất Excel',
            icon: const Icon(Icons.download),
            onPressed: () => _exportExcel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs chọn loại phiếu
          Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeTab(0, 'Nhập kho', Icons.input),
                ),
                Expanded(
                  child: _buildTypeTab(1, 'Xuất kho', Icons.outbox),
                ),
                Expanded(
                  child: _buildTypeTab(2, 'Xuất chợ', Icons.storefront),
                ),
                Expanded(
                  child: _buildTypeTab(3, 'Nhập chợ', Icons.shopping_basket),
                ),
              ],
            ),
          ),
          _buildFilterBar(context),
          if (_showAdvancedFilters) _buildAdvancedFilterBar(context),
          Expanded(
            child: BlocBuilder<InvoiceHistoryBloc, InvoiceHistoryState>(
              builder: (context, state) {
                if (state.status == HistoryStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == HistoryStatus.failure) {
                  return Center(
                    child: Text(
                      'Lỗi: ${state.errorMessage ?? 'Không xác định'}',
                    ),
                  );
                }
                if (state.invoices.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy phiếu nào'),
                  );
                }
                return _buildList(context, state.invoices);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab(int type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        context.read<InvoiceHistoryBloc>().add(LoadInvoices(type));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm theo khách hàng hoặc mã phiếu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => _onFilterChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int?>(
              value: _daysFilter,
              decoration: const InputDecoration(
                labelText: 'Thời gian',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 0, child: Text('Hôm nay')),
                DropdownMenuItem(value: 7, child: Text('7 ngày qua')),
                DropdownMenuItem(value: 30, child: Text('30 ngày qua')),
              ],
              onChanged: (value) {
                setState(() => _daysFilter = value);
                _onFilterChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bộ lọc nâng cao',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pigTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Loại heo',
                    hintText: 'VD: Nái, Thịt...',
                    prefixIcon: Icon(Icons.pets, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _batchNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Số lô',
                    hintText: 'VD: LOT001...',
                    prefixIcon: Icon(Icons.qr_code, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Khối lượng từ (kg)',
                    prefixIcon: Icon(Icons.scale, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Khối lượng đến (kg)',
                    prefixIcon: Icon(Icons.scale, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị từ (đ)',
                    prefixIcon: Icon(Icons.attach_money, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá trị đến (đ)',
                    prefixIcon: Icon(Icons.attach_money, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nút tìm kiếm
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Tìm kiếm'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<InvoiceEntity> invoices) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = invoices[index];

        return Card(
          elevation: 1,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.partnerName ?? 'Khách lẻ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(invoice.createdDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(invoice.finalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Xóa phiếu',
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                            ),
                            onPressed: () =>
                                _confirmAndDelete(context, invoice),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, InvoiceEntity invoice) async {
    // If it's an import invoice (type 0), check if deletion would cause negative inventory
    if (invoice.type == 0) {
      final canDelete = await _canDeleteImportInvoice(invoice);
      if (!canDelete) {
        if (context.mounted) {
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
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu'),
        content: Text(
          'Bạn có chắc muốn xóa phiếu của '
          '${invoice.partnerName ?? 'khách lẻ'} '
          'ngày ${DateFormat('dd/MM').format(invoice.createdDate)}?',
        ),
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

    if (result == true) {
      await sl<IInvoiceRepository>().deleteInvoice(invoice.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa phiếu')),
        );
      }
    }
  }

  /// Check if deleting an import invoice would cause negative inventory
  Future<bool> _canDeleteImportInvoice(InvoiceEntity invoice) async {
    try {
      final repo = sl<IInvoiceRepository>();
      final importInvoices = await repo.watchInvoices(type: 0).first;
      final exportInvoices = await repo.watchInvoices(type: 2).first;

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
}
