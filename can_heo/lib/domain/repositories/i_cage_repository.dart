import '../entities/cage.dart';

abstract class ICageRepository {
  /// Theo dõi tất cả chuồng kho
  Stream<List<CageEntity>> watchAllCages();
  
  /// Lấy tất cả chuồng kho
  Future<List<CageEntity>> getAllCages();
  
  /// Lấy thông tin một chuồng theo ID
  Future<CageEntity?> getCageById(String id);
  
  /// Thêm chuồng mới
  Future<void> addCage(CageEntity cage);
  
  /// Cập nhật thông tin chuồng
  Future<void> updateCage(CageEntity cage);
  
  /// Xóa chuồng
  Future<void> deleteCage(String id);
}
