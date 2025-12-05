import 'package:drift/drift.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/i_invoice_repository.dart';
import '../local/database.dart';
import '../local/tables/invoices.dart';
import '../local/tables/weighing_details.dart';

class InvoiceRepositoryImpl implements IInvoiceRepository {
  final AppDatabase _db;

  InvoiceRepositoryImpl(this._db);

  @override
  Stream<List<InvoiceEntity>> watchInvoices(int type) {
    // Lấy dữ liệu từ DAO và map sang Entity
    return _db.invoicesDao.watchInvoicesByType(type).map((dtos) {
      return dtos.map((dto) {
        // Lưu ý: Ở màn hình danh sách, ta chưa cần load chi tiết cân (details) để tối ưu
        return InvoiceEntity(
          id: dto.invoice.id,
          partnerId: dto.partner?.id,
          partnerName: dto.partner?.name ?? 'Khách lẻ',
          type: dto.invoice.type,
          createdDate: dto.invoice.createdDate,
          totalWeight: dto.invoice.totalWeight,
          totalQuantity: dto.invoice.totalQuantity,
          finalAmount: dto.invoice.finalAmount,
          details: const [], // Danh sách rỗng khi xem ở dashboard
        );
      }).toList();
    });
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(String id) async {
    // 1. Lấy thông tin phiếu
    final invoiceQuery = _db.select(_db.invoices)..where((tbl) => tbl.id.equals(id));
    final invoiceResult = await invoiceQuery.getSingleOrNull();

    if (invoiceResult == null) return null;

    // 2. Lấy tên khách hàng (nếu có)
    String? partnerName;
    if (invoiceResult.partnerId != null) {
      final partner = await _db.partnersDao.getPartnerById(invoiceResult.partnerId!);
      partnerName = partner?.name;
    }

    // 3. Lấy chi tiết các mã cân
    final detailsDtos = await _db.weighingDetailsDao.watchDetailsByInvoice(id).first;
    final detailsEntities = detailsDtos.map((d) => WeighingItemEntity(
      id: d.id,
      sequence: d.sequence,
      weight: d.weight,
      quantity: d.quantity,
      time: d.weighingTime,
    )).toList();

    // 4. Gộp lại thành Entity hoàn chỉnh
    return InvoiceEntity(
      id: invoiceResult.id,
      partnerId: invoiceResult.partnerId,
      partnerName: partnerName,
      type: invoiceResult.type,
      createdDate: invoiceResult.createdDate,
      totalWeight: invoiceResult.totalWeight,
      totalQuantity: invoiceResult.totalQuantity,
      finalAmount: invoiceResult.finalAmount,
      details: detailsEntities,
    );
  }

  @override
  Future<void> createInvoice(InvoiceEntity invoice) async {
    await _db.invoicesDao.createInvoice(InvoicesCompanion(
      id: Value(invoice.id),
      partnerId: Value(invoice.partnerId),
      type: Value(invoice.type),
      createdDate: Value(invoice.createdDate),
      totalWeight: Value(invoice.totalWeight),
      totalQuantity: Value(invoice.totalQuantity),
      finalAmount: Value(invoice.finalAmount),
      // Các trường tiền khác mặc định là 0
    ));
  }

  @override
  Future<void> addWeighingItem(String invoiceId, WeighingItemEntity item) async {
    // 1. Thêm mã cân vào bảng chi tiết
    await _db.weighingDetailsDao.insertDetail(WeighingDetailsCompanion(
      id: Value(item.id),
      invoiceId: Value(invoiceId),
      sequence: Value(item.sequence),
      weight: Value(item.weight),
      quantity: Value(item.quantity),
      weighingTime: Value(item.time),
    ));

    // 2. Tự động tính lại tổng trọng lượng & số lượng cho phiếu
    final totals = await _db.weighingDetailsDao.getInvoiceTotals(invoiceId);
    
    // 3. Update ngược lại bảng Invoice để hiển thị nhanh
    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId))).write(
      InvoicesCompanion(
        totalWeight: Value(totals['totalWeight']!),
        totalQuantity: Value(totals['totalQuantity']!.toInt()),
      ),
    );
  }
}