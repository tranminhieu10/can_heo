import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';
import '../../history/invoice_detail_screen.dart';

/// Grid showing saved invoices for market export
class SavedInvoicesGrid extends StatelessWidget {
  final TextEditingController searchPartnerController;
  final TextEditingController searchPigTypeController;
  final TextEditingController searchQuantityController;
  final Set<String> activeSearchColumns;
  final VoidCallback onClearFilters;
  final NumberFormat numberFormat;
  final NumberFormat currencyFormat;

  const SavedInvoicesGrid({
    super.key,
    required this.searchPartnerController,
    required this.searchPigTypeController,
    required this.searchQuantityController,
    required this.activeSearchColumns,
    required this.onClearFilters,
    required this.numberFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvoiceEntity>>(
      stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var invoices = snapshot.data!;
        if (invoices.isEmpty) {
          return const Center(child: Text('Chưa có phiếu xuất nào'));
        }

        // Filter invoices
        invoices = invoices.where((inv) {
          final partner = searchPartnerController.text.trim().toLowerCase();
          final pigType = searchPigTypeController.text.trim().toLowerCase();
          final quantity = searchQuantityController.text.trim();

          final invPartner = (inv.partnerName ?? 'Khách lẻ').toLowerCase();
          final invPigType = inv.details.isNotEmpty
              ? (inv.details.first.pigType ?? '').toLowerCase()
              : '';
          final invQuantity = '${inv.totalQuantity}';

          bool matches = true;
          if (partner.isNotEmpty && !invPartner.contains(partner)) {
            matches = false;
          }
          if (pigType.isNotEmpty && !invPigType.contains(pigType)) {
            matches = false;
          }
          if (quantity.isNotEmpty && !invQuantity.contains(quantity)) {
            matches = false;
          }
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
                    if (activeSearchColumns.isNotEmpty)
                      TextButton.icon(
                        onPressed: onClearFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label:
                            const Text('Xóa lọc', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              // Data table
              Expanded(
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
                                    '${numberFormat.format(inv.totalWeight)} kg',
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${numberFormat.format(inv.deduction)} kg',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${numberFormat.format(inv.netWeight)} kg',
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    currencyFormat.format(inv.pricePerKg),
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    currencyFormat.format(inv.subtotal),
                                    style: const TextStyle(fontSize: 13)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    currencyFormat.format(inv.discount),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.red)))),
                            DataCell(Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    currencyFormat.format(inv.finalAmount),
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
                                    Navigator.of(context).push(MaterialPageRoute(
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
                                      if (context.mounted) {
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
}
