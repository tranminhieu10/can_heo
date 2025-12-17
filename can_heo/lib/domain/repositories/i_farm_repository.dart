import '../entities/farm.dart';

abstract class IFarmRepository {
  /// Lấy tất cả trại của một công ty (partnerId)
  Stream<List<FarmEntity>> watchFarmsByPartner(String partnerId);
  
  /// Lấy tất cả trại
  Stream<List<FarmEntity>> watchAllFarms();
  
  /// Lấy trại theo ID
  Future<FarmEntity?> getFarmById(String id);
  
  /// Thêm trại mới
  Future<void> addFarm(FarmEntity farm);
  
  /// Cập nhật trại
  Future<void> updateFarm(FarmEntity farm);
  
  /// Xóa trại
  Future<void> deleteFarm(String id);
}
