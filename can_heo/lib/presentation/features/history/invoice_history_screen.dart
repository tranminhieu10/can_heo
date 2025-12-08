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
  int? _daysFilter; // null = tất cả
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Gửi event lọc xuống Bloc với debounce
  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<InvoiceHistoryBloc>().add(
            FilterInvoices(
              keyword: _searchController.text.trim().isEmpty
                  ? null
                  : _searchController.text.trim(),
              daysFilter: _daysFilter,
            ),
          );
    });
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
            tooltip: 'Xuất Excel',
            icon: const Icon(Icons.download),
            onPressed: () => _exportExcel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child:
                BlocBuilder<InvoiceHistoryBloc, InvoiceHistoryState>(
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
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả'),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text('Hôm nay'),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text('7 ngày qua'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 ngày qua'),
                ),
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

  Widget _buildList(BuildContext context, List<InvoiceEntity> invoices) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
                  builder: (_) =>
                      InvoiceDetailScreen(invoiceId: invoice.id),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa phiếu')),
      );
    }
  }
}
