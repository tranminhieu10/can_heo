import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/invoice.dart';
import '../../domain/entities/transaction.dart';

class ExcelExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  static final _numberFormat = NumberFormat('#,##0.0', 'vi_VN');

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
        TextCellValue(_dateFormat.format(invoice.createdDate)),
        TextCellValue(invoice.partnerName ?? 'Khách lẻ'),
        TextCellValue(typeLabel),
        DoubleCellValue(invoice.totalWeight),
        IntCellValue(invoice.totalQuantity),
        TextCellValue(_currencyFormat.format(invoice.finalAmount)),
      ];

      sheet.appendRow(dataRow);
    }

    await _saveExcelFile(excel, 'bao_cao_lich_su_phieu');
  }

  /// Xuất báo cáo Bán hàng / Nhập hàng ra Excel
  static Future<void> exportSalesOrPurchaseReport({
    required List<InvoiceEntity> invoices,
    required String reportType, // 'ban_hang' hoặc 'nhap_hang'
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (invoices.isEmpty) {
      throw Exception('Không có dữ liệu để xuất.');
    }

    final excel = Excel.createExcel();
    final sheetName = reportType == 'ban_hang' ? 'BanHang' : 'NhapHang';
    final sheet = excel[sheetName];

    // Title
    final title = reportType == 'ban_hang' 
        ? 'BÁO CÁO BÁN HÀNG (Xuất chợ)'
        : 'BÁO CÁO NHẬP HÀNG (Nhập chợ)';
    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([TextCellValue('Từ ${_dateFormat.format(startDate)} đến ${_dateFormat.format(endDate)}')]);
    sheet.appendRow([]); // Empty row

    // Header
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Đối tác'),
      TextCellValue('SL con'),
      TextCellValue('KL (kg)'),
      TextCellValue('BQ (kg)'),
      TextCellValue('Đơn giá'),
      TextCellValue('Thành tiền'),
      TextCellValue('Ghi chú'),
    ]);

    // Data rows
    int totalQuantity = 0;
    double totalWeight = 0;
    double totalAmount = 0;

    for (final inv in invoices) {
      final avgWeight = inv.totalQuantity > 0 
          ? inv.totalWeight / inv.totalQuantity 
          : 0.0;

      sheet.appendRow([
        TextCellValue(_dateFormat.format(inv.createdDate)),
        TextCellValue(inv.partnerName ?? 'N/A'),
        IntCellValue(inv.totalQuantity),
        TextCellValue(_numberFormat.format(inv.totalWeight)),
        TextCellValue(_numberFormat.format(avgWeight)),
        TextCellValue(_currencyFormat.format(inv.pricePerKg)),
        TextCellValue(_currencyFormat.format(inv.finalAmount)),
        TextCellValue(inv.note ?? ''),
      ]);

      totalQuantity += inv.totalQuantity;
      totalWeight += inv.totalWeight;
      totalAmount += inv.finalAmount;
    }

    // Total row
    final avgWeight = totalQuantity > 0 ? totalWeight / totalQuantity : 0;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0;

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TỔNG'),
      TextCellValue('${invoices.length} phiếu'),
      IntCellValue(totalQuantity),
      TextCellValue(_numberFormat.format(totalWeight)),
      TextCellValue(_numberFormat.format(avgWeight)),
      TextCellValue(_currencyFormat.format(avgPrice)),
      TextCellValue(_currencyFormat.format(totalAmount)),
      TextCellValue(''),
    ]);

    final fileName = reportType == 'ban_hang' 
        ? 'bao_cao_ban_hang' 
        : 'bao_cao_nhap_hang';
    await _saveExcelFile(excel, fileName);
  }

  /// Xuất báo cáo theo đối tác cụ thể
  static Future<void> exportByPartnerReport({
    required List<InvoiceEntity> invoices,
    required String partnerName,
    required String reportType, // 'ban_hang' hoặc 'nhap_hang'
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (invoices.isEmpty) {
      throw Exception('Không có dữ liệu để xuất.');
    }

    // Sắp xếp theo ngày
    final sortedInvoices = List<InvoiceEntity>.from(invoices)
      ..sort((a, b) => a.createdDate.compareTo(b.createdDate));

    final excel = Excel.createExcel();
    final sheetName = reportType == 'ban_hang' ? 'BanHang' : 'NhapHang';
    final sheet = excel[sheetName];

    // Title
    final title = reportType == 'ban_hang' 
        ? 'BÁO CÁO BÁN HÀNG'
        : 'BÁO CÁO NHẬP HÀNG';
    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([TextCellValue('Đối tác: $partnerName')]);
    sheet.appendRow([TextCellValue('Từ ${_dateFormat.format(startDate)} đến ${_dateFormat.format(endDate)}')]);
    sheet.appendRow([]); // Empty row

    // Header
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('SL con'),
      TextCellValue('KL (kg)'),
      TextCellValue('BQ (kg)'),
      TextCellValue('Đơn giá'),
      TextCellValue('Thành tiền'),
      TextCellValue('Ghi chú'),
    ]);

    // Data rows
    int totalQuantity = 0;
    double totalWeight = 0;
    double totalAmount = 0;

    for (final inv in sortedInvoices) {
      final avgWeight = inv.totalQuantity > 0 
          ? inv.totalWeight / inv.totalQuantity 
          : 0.0;

      sheet.appendRow([
        TextCellValue(_dateFormat.format(inv.createdDate)),
        IntCellValue(inv.totalQuantity),
        TextCellValue(_numberFormat.format(inv.totalWeight)),
        TextCellValue(_numberFormat.format(avgWeight)),
        TextCellValue(_currencyFormat.format(inv.pricePerKg)),
        TextCellValue(_currencyFormat.format(inv.finalAmount)),
        TextCellValue(inv.note ?? ''),
      ]);

      totalQuantity += inv.totalQuantity;
      totalWeight += inv.totalWeight;
      totalAmount += inv.finalAmount;
    }

    // Total row
    final avgWeight = totalQuantity > 0 ? totalWeight / totalQuantity : 0;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0;

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TỔNG'),
      IntCellValue(totalQuantity),
      TextCellValue(_numberFormat.format(totalWeight)),
      TextCellValue(_numberFormat.format(avgWeight)),
      TextCellValue(_currencyFormat.format(avgPrice)),
      TextCellValue(_currencyFormat.format(totalAmount)),
      TextCellValue('${sortedInvoices.length} phiếu'),
    ]);

    // Tạo tên file an toàn (loại bỏ ký tự đặc biệt)
    final safePartnerName = partnerName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_');
    final fileName = reportType == 'ban_hang' 
        ? 'bao_cao_ban_hang_$safePartnerName' 
        : 'bao_cao_nhap_hang_$safePartnerName';
    await _saveExcelFile(excel, fileName);
  }

  /// Xuất báo cáo Chi phí ra Excel
  static Future<void> exportCostReport({
    required double otherCost,
    required double transportFee,
    required double rejectAmount,
    required String? otherCostNote,
    required String? rejectNote,
    required List<TransactionEntity> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['ChiPhi'];

    // Title
    sheet.appendRow([TextCellValue('BÁO CÁO CHI PHÍ')]);
    sheet.appendRow([TextCellValue('Từ ${_dateFormat.format(startDate)} đến ${_dateFormat.format(endDate)}')]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([TextCellValue('TỔNG HỢP CHI PHÍ')]);
    sheet.appendRow([
      TextCellValue('Loại chi phí'),
      TextCellValue('Số tiền'),
      TextCellValue('Ghi chú'),
    ]);
    sheet.appendRow([
      TextCellValue('Chi phí khác'),
      TextCellValue(_currencyFormat.format(otherCost)),
      TextCellValue(otherCostNote ?? ''),
    ]);
    sheet.appendRow([
      TextCellValue('Cước xe'),
      TextCellValue(_currencyFormat.format(transportFee)),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('Thải loại'),
      TextCellValue(_currencyFormat.format(rejectAmount)),
      TextCellValue(rejectNote ?? ''),
    ]);
    sheet.appendRow([
      TextCellValue('TỔNG CỘNG'),
      TextCellValue(_currencyFormat.format(otherCost + transportFee + rejectAmount)),
      TextCellValue(''),
    ]);

    // Transactions
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('CHI TIẾT GIAO DỊCH CHI PHÍ')]);
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Loại'),
      TextCellValue('Đối tác'),
      TextCellValue('Số tiền'),
      TextCellValue('Ghi chú'),
    ]);

    final costTransactions = transactions.where((t) {
      final note = t.note?.toLowerCase() ?? '';
      return t.type == 1 &&
          (note.contains('cước') ||
              note.contains('xe') ||
              note.contains('thải') ||
              note.contains('loại') ||
              note.contains('chi phí') ||
              note.contains('khác'));
    }).toList();

    for (final t in costTransactions) {
      sheet.appendRow([
        TextCellValue(_dateFormat.format(t.date)),
        TextCellValue(_getCostType(t.note)),
        TextCellValue(t.partnerName ?? 'N/A'),
        TextCellValue(_currencyFormat.format(t.amount)),
        TextCellValue(t.note ?? ''),
      ]);
    }

    await _saveExcelFile(excel, 'bao_cao_chi_phi');
  }

  /// Xuất báo cáo Công nợ ra Excel
  static Future<void> exportDebtReport({
    required double totalDebt,
    required double totalPaid,
    required double totalDebtPaid,
    required double remaining,
    required List<TransactionEntity> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['CongNo'];

    // Title
    sheet.appendRow([TextCellValue('BÁO CÁO CÔNG NỢ')]);
    sheet.appendRow([TextCellValue('Từ ${_dateFormat.format(startDate)} đến ${_dateFormat.format(endDate)}')]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([TextCellValue('TỔNG HỢP CÔNG NỢ')]);
    sheet.appendRow([
      TextCellValue('Nợ phát sinh'),
      TextCellValue(_currencyFormat.format(totalDebt)),
    ]);
    sheet.appendRow([
      TextCellValue('Đã thanh toán'),
      TextCellValue(_currencyFormat.format(totalPaid)),
    ]);
    sheet.appendRow([
      TextCellValue('Đã trả nợ'),
      TextCellValue(_currencyFormat.format(totalDebtPaid)),
    ]);
    sheet.appendRow([
      TextCellValue('Còn nợ'),
      TextCellValue(_currencyFormat.format(remaining)),
    ]);

    // Transactions
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('LỊCH SỬ THANH TOÁN / TRẢ NỢ')]);
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Đối tác'),
      TextCellValue('Loại'),
      TextCellValue('Số tiền'),
      TextCellValue('Ghi chú'),
    ]);

    final paymentTransactions = transactions.where((t) {
      final note = t.note?.toLowerCase() ?? '';
      return t.type == 1 &&
          (note.contains('thanh toán') || note.contains('trả nợ'));
    }).toList();

    for (final t in paymentTransactions) {
      final isDebtPayment = t.note?.toLowerCase().contains('trả nợ') == true;
      sheet.appendRow([
        TextCellValue(_dateFormat.format(t.date)),
        TextCellValue(t.partnerName ?? 'N/A'),
        TextCellValue(isDebtPayment ? 'Trả nợ' : 'Thanh toán'),
        TextCellValue(_currencyFormat.format(t.amount)),
        TextCellValue(t.note ?? ''),
      ]);
    }

    await _saveExcelFile(excel, 'bao_cao_cong_no');
  }

  /// Xuất báo cáo Tổng hợp ra Excel
  static Future<void> exportOverviewReport({
    required List<InvoiceEntity> imports,
    required List<InvoiceEntity> exports,
    required double otherCost,
    required double transportFee,
    required double rejectAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    
    // Sheet 1: Tổng hợp
    final overviewSheet = excel['TongHop'];
    overviewSheet.appendRow([TextCellValue('BÁO CÁO TỔNG HỢP CHỢ')]);
    overviewSheet.appendRow([TextCellValue('Từ ${_dateFormat.format(startDate)} đến ${_dateFormat.format(endDate)}')]);
    overviewSheet.appendRow([]);

    final importAmount = imports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final exportAmount = exports.fold<double>(0, (sum, inv) => sum + inv.finalAmount);
    final totalCost = otherCost + transportFee + rejectAmount;
    final profit = exportAmount - importAmount - totalCost;

    overviewSheet.appendRow([TextCellValue('TỔNG KẾT')]);
    overviewSheet.appendRow([TextCellValue('Tiền nhập hàng'), TextCellValue(_currencyFormat.format(importAmount))]);
    overviewSheet.appendRow([TextCellValue('Tiền bán hàng'), TextCellValue(_currencyFormat.format(exportAmount))]);
    overviewSheet.appendRow([TextCellValue('Chi phí'), TextCellValue(_currencyFormat.format(totalCost))]);
    overviewSheet.appendRow([TextCellValue(profit >= 0 ? 'LÃI' : 'LỖ'), TextCellValue(_currencyFormat.format(profit.abs()))]);

    // Sheet 2: Bán hàng
    final salesSheet = excel['BanHang'];
    salesSheet.appendRow([TextCellValue('BÁN HÀNG (Xuất chợ)')]);
    salesSheet.appendRow([]);
    _addInvoiceTableToSheet(salesSheet, exports);

    // Sheet 3: Nhập hàng
    final purchaseSheet = excel['NhapHang'];
    purchaseSheet.appendRow([TextCellValue('NHẬP HÀNG (Nhập chợ)')]);
    purchaseSheet.appendRow([]);
    _addInvoiceTableToSheet(purchaseSheet, imports);

    await _saveExcelFile(excel, 'bao_cao_tong_hop');
  }

  static void _addInvoiceTableToSheet(Sheet sheet, List<InvoiceEntity> invoices) {
    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Đối tác'),
      TextCellValue('SL con'),
      TextCellValue('KL (kg)'),
      TextCellValue('BQ (kg)'),
      TextCellValue('Đơn giá'),
      TextCellValue('Thành tiền'),
      TextCellValue('Ghi chú'),
    ]);

    int totalQuantity = 0;
    double totalWeight = 0;
    double totalAmount = 0;

    for (final inv in invoices) {
      final avgWeight = inv.totalQuantity > 0 
          ? inv.totalWeight / inv.totalQuantity 
          : 0.0;

      sheet.appendRow([
        TextCellValue(_dateFormat.format(inv.createdDate)),
        TextCellValue(inv.partnerName ?? 'N/A'),
        IntCellValue(inv.totalQuantity),
        TextCellValue(_numberFormat.format(inv.totalWeight)),
        TextCellValue(_numberFormat.format(avgWeight)),
        TextCellValue(_currencyFormat.format(inv.pricePerKg)),
        TextCellValue(_currencyFormat.format(inv.finalAmount)),
        TextCellValue(inv.note ?? ''),
      ]);

      totalQuantity += inv.totalQuantity;
      totalWeight += inv.totalWeight;
      totalAmount += inv.finalAmount;
    }

    final avgWeight = totalQuantity > 0 ? totalWeight / totalQuantity : 0;
    final avgPrice = totalWeight > 0 ? totalAmount / totalWeight : 0;

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TỔNG'),
      TextCellValue('${invoices.length} phiếu'),
      IntCellValue(totalQuantity),
      TextCellValue(_numberFormat.format(totalWeight)),
      TextCellValue(_numberFormat.format(avgWeight)),
      TextCellValue(_currencyFormat.format(avgPrice)),
      TextCellValue(_currencyFormat.format(totalAmount)),
      TextCellValue(''),
    ]);
  }

  static String _getCostType(String? note) {
    final lowerNote = note?.toLowerCase() ?? '';
    if (lowerNote.contains('cước') || lowerNote.contains('xe')) {
      return 'Cước xe';
    } else if (lowerNote.contains('thải') || lowerNote.contains('loại')) {
      return 'Thải loại';
    }
    return 'Chi phí khác';
  }

  static Future<void> _saveExcelFile(Excel excel, String fileNamePrefix) async {
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Không tạo được file Excel.');
    }

    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục lưu báo cáo Excel',
    );
    if (dirPath == null) return;

    final fileName = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(p.join(dirPath, fileName));

    await file.writeAsBytes(bytes, flush: true);
  }
}
