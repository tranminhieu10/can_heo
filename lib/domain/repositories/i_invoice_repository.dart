import '../entities/invoice.dart';

abstract class IInvoiceRepository {
  // Xem danh sách phiếu theo loại (Nhập/Xuất)
  Stream<List<InvoiceEntity>> watchInvoices(int type);
  
  // Lấy chi tiết 1 phiếu (kèm các mã cân bên trong)
  Future<InvoiceEntity?> getInvoiceDetail(String id);
  
  // Tạo phiếu mới
  Future<void> createInvoice(InvoiceEntity invoice);
  
  // Thêm 1 mã cân vào phiếu đang cân
  Future<void> addWeighingItem(String invoiceId, WeighingItemEntity item);
}