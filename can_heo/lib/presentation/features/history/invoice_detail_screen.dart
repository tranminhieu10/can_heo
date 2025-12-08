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

    final repo = sl<IInvoiceRepository>();
    await repo.deleteInvoice(widget.invoiceId);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa phiếu')),
    );
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
