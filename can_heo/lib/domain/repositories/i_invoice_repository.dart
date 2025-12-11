import '../entities/invoice.dart';

abstract class IInvoiceRepository {
  // [TỐI ƯU] Xem danh sách phiếu có lọc
  Stream<List<InvoiceEntity>> watchInvoices({
    required int type,
    String? keyword,
    int? daysAgo, // null = tất cả, 0 = hôm nay, 7 = 7 ngày...
  });

  // Lấy chi tiết 1 phiếu
  Future<InvoiceEntity?> getInvoiceDetail(String id);

  // Tạo phiếu mới
  Future<void> createInvoice(InvoiceEntity invoice);

  // Cập nhật phiếu
  Future<void> updateInvoice(InvoiceEntity invoice);

  // Thêm 1 mã cân
  Future<void> addWeighingItem(String invoiceId, WeighingItemEntity item);

  // Cập nhật 1 mã cân
  Future<void> updateWeighingItem(WeighingItemEntity item);

    // Xóa 1 phiếu

    Future<void> deleteInvoice(String id);

  

    // Xem tồn kho của 1 loại heo

    Stream<int> watchPigTypeInventory(String pigType);

  }

  