import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/invoice.dart';

class PrintingService {
  static Future<void> printInvoice(InvoiceEntity invoice) async {
    // Sử dụng font mặc định để tránh lỗi nếu chưa có assets
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return _buildPdfLayout(invoice);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Phieu_${invoice.partnerName}',
    );
  }

  static pw.Widget _buildPdfLayout(InvoiceEntity invoice) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
            child: pw.Text("PHIẾU CÂN HEO",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Khách hàng: ${invoice.partnerName ?? 'Khách lẻ'}"),
          pw.Text("Ngày: ${dateFormat.format(invoice.createdDate)}"),
        ]),
        pw.Divider(),
        pw.Table.fromTextArray(
          headers: ['STT', 'KL (kg)', 'SL', 'Giờ'],
          data: invoice.details
              .map((e) => [
                    e.sequence.toString(),
                    e.weight.toString(),
                    e.quantity.toString(),
                    DateFormat('HH:mm').format(e.time)
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text("TỔNG TIỀN: ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(currencyFormat.format(invoice.finalAmount),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ]),
      ],
    );
  }
}