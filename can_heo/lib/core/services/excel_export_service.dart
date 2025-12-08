import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/invoice.dart';

class ExcelExportService {
  /// Xuất danh sách phiếu ra file Excel (.xlsx)
  static Future<void> exportInvoicesToExcel(
    List<InvoiceEntity> invoices,
  ) async {
    if (invoices.isEmpty) {
      throw Exception('Không có dữ liệu để xuất.');
    }

    // Tạo workbook & sheet
    final excel = Excel.createExcel();
    final sheet = excel['LichSuPhieu'];

    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    // ----- HEADER -----
    final headerRow = <CellValue>[
      TextCellValue('Ngày'),
      TextCellValue('Khách hàng'),
      TextCellValue('Loại phiếu'),
      TextCellValue('Tổng trọng lượng (kg)'),
      TextCellValue('Tổng số con'),
      TextCellValue('Thành tiền'),
    ];
    sheet.appendRow(headerRow);

    // ----- DATA -----
    for (final invoice in invoices) {
      final typeLabel = invoice.type == 1
          ? 'Nhập kho'
          : (invoice.type == 2 ? 'Xuất chợ' : invoice.type.toString());

      final dataRow = <CellValue>[
        TextCellValue(dateFormat.format(invoice.createdDate)),
        TextCellValue(invoice.partnerName ?? 'Khách lẻ'),
        TextCellValue(typeLabel),
        DoubleCellValue(invoice.totalWeight),
        IntCellValue(invoice.totalQuantity),
        TextCellValue(currencyFormat.format(invoice.finalAmount)),
      ];

      sheet.appendRow(dataRow);
    }

    // Encode ra bytes
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Không tạo được file Excel.');
    }

    // Hỏi user chọn thư mục lưu
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục lưu báo cáo Excel',
    );
    if (dirPath == null) return; // user bấm Hủy

    final fileName =
        'bao_cao_lich_su_phieu_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(p.join(dirPath, fileName));

    await file.writeAsBytes(bytes, flush: true);
  }
}
