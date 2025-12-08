import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/invoice.dart';

class PrintingService {
  // In 1 phiếu cân
  static Future<void> printInvoice(InvoiceEntity invoice) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final timeFormat = DateFormat('HH:mm');
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final styleNormal = pw.TextStyle(fontSize: 10);
          final styleBold = pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          );
          final styleHeader = pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header
              pw.Center(
                child: pw.Text('PHIẾU CÂN HEO', style: styleHeader),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Ngày: ${dateFormat.format(invoice.createdDate)}',
                  style: styleNormal,
                ),
              ),
              pw.SizedBox(height: 16),

              // 2. Thông tin khách hàng
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Khách hàng: ${invoice.partnerName ?? 'Khách lẻ'}',
                    style: styleBold,
                  ),
                  pw.Text(
                    'Số phiếu: ${invoice.id}',
                    style: styleNormal,
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // 3. Bảng kê chi tiết
              pw.Table.fromTextArray(
                headers: const ['STT', 'KL (kg)', 'SL', 'Giờ'],
                data: invoice.details.map((item) {
                  return [
                    item.sequence.toString(),
                    item.weight.toStringAsFixed(1),
                    item.quantity.toString(),
                    timeFormat.format(item.time),
                  ];
                }).toList(),
                headerStyle: styleBold,
                cellStyle: styleNormal,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FixedColumnWidth(60),
                },
              ),
              pw.SizedBox(height: 12),

              // 4. Tổng kết
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Tổng trọng lượng: ${invoice.totalWeight.toStringAsFixed(1)} kg',
                      style: styleBold,
                    ),
                    pw.Text(
                      'Tổng số con: ${invoice.totalQuantity}',
                      style: styleNormal,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'THÀNH TIỀN: ${currencyFormat.format(invoice.finalAmount)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // 5. Chữ ký
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Người lập phiếu', style: styleNormal),
                  pw.Text('Khách hàng', style: styleNormal),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
