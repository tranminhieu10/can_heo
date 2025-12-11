import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/printing_service.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Future<InvoiceEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<IInvoiceRepository>().getInvoiceDetail(widget.invoiceId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = sl<IInvoiceRepository>().getInvoiceDetail(widget.invoiceId);
    });
  }

  Future<void> _deleteInvoice() async {
    final repo = sl<IInvoiceRepository>();
    
    // Get invoice details first
    final invoice = await repo.getInvoiceDetail(widget.invoiceId);
    if (invoice == null) return;
    
    // If it's an import invoice (type 0), check if deletion would cause negative inventory
    if (invoice.type == 0) {
      final canDelete = await _canDeleteImportInvoice(invoice);
      if (!canDelete) {
        if (mounted) {
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
    }
    
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

    if (confirmed != true) return;

    await repo.deleteInvoice(widget.invoiceId);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa phiếu')),
    );
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvoiceEntity?>(
      future: _future,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final invoice = snapshot.data;
        final canPrint = invoice != null && !waiting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('CHI TIẾT PHIẾU'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Tải lại',
                onPressed: waiting ? null : _reload,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Xóa phiếu',
                onPressed: waiting ? null : _deleteInvoice,
              ),
            ],
          ),
          floatingActionButton: canPrint
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.print),
                  label: const Text('IN PHIẾU'),
                  onPressed: () {
                    if (invoice != null) {
                      PrintingService.printInvoice(invoice);
                    }
                  },
                )
              : null,
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<InvoiceEntity?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Lỗi: ${snapshot.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final invoice = snapshot.data;
    if (invoice == null) {
      return const Center(
        child: Text('Không tìm thấy phiếu này'),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.0', 'en_US');
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PHIẾU CÂN',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ngày tạo: ${dateFormat.format(invoice.createdDate)}',
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                label: 'Khách hàng',
                value: invoice.partnerName ?? 'Khách lẻ',
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                label: 'Tổng trọng lượng',
                value: '${numberFormat.format(invoice.totalWeight)} kg',
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                label: 'Tổng số con',
                value: invoice.totalQuantity.toString(),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                label: 'Thành tiền',
                value: currencyFormat.format(invoice.finalAmount),
                isBold: true,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'CHI TIẾT MÃ CÂN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailsTable(invoice.details, numberFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTable(
    List<WeighingItemEntity> details,
    NumberFormat numberFormat,
  ) {
    if (details.isEmpty) {
      return const Text('Không có mã cân nào trong phiếu này.');
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FixedColumnWidth(50),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(100),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'STT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Khối lượng (kg)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Số con',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Giờ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...details.map(
          (item) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.sequence.toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(numberFormat.format(item.weight)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.quantity.toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  DateFormat('HH:mm').format(item.time),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
