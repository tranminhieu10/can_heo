import '../entities/supply.dart';

/// Interface Repository cho Vật tư
abstract class ISupplyRepository {
  /// Lấy tất cả vật tư
  Future<List<SupplyEntity>> getAllSupplies();

  /// Stream theo dõi vật tư
  Stream<List<SupplyEntity>> watchSupplies();

  /// Lấy vật tư theo ID
  Future<SupplyEntity?> getSupplyById(String id);

  /// Tạo vật tư mới
  Future<void> createSupply(SupplyEntity supply);

  /// Cập nhật vật tư
  Future<void> updateSupply(SupplyEntity supply);

  /// Xóa vật tư
  Future<void> deleteSupply(String id);

  /// Nhập vật tư (tăng số lượng)
  Future<void> importSupply(String supplyId, double quantity, {double? pricePerUnit, String? note});

  /// Xuất vật tư (giảm số lượng)
  Future<void> exportSupply(String supplyId, double quantity, {String? note});

  /// Lấy lịch sử giao dịch của vật tư
  Future<List<SupplyTransactionEntity>> getTransactionHistory(String supplyId);

  /// Stream theo dõi lịch sử giao dịch
  Stream<List<SupplyTransactionEntity>> watchTransactionHistory({String? supplyId});

  /// Lấy vật tư sắp hết (dưới mức tối thiểu)
  Future<List<SupplyEntity>> getLowStockSupplies();
}
