import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/farms.dart';

part 'farms_dao.g.dart';

@DriftAccessor(tables: [Farms])
class FarmsDao extends DatabaseAccessor<AppDatabase> with _$FarmsDaoMixin {
  FarmsDao(AppDatabase db) : super(db);

  /// Lấy tất cả trại
  Stream<List<Farm>> watchAllFarms() {
    return select(farms).watch();
  }

  /// Lấy trại theo công ty (partnerId)
  Stream<List<Farm>> watchFarmsByPartner(String partnerId) {
    return (select(farms)..where((tbl) => tbl.partnerId.equals(partnerId))).watch();
  }

  /// Lấy trại theo ID
  Future<Farm?> getFarmById(String id) {
    return (select(farms)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Thêm trại mới
  Future<int> insertFarm(FarmsCompanion entry) {
    return into(farms).insert(entry);
  }

  /// Cập nhật trại
  Future<bool> updateFarm(Farm entry) {
    return update(farms).replace(entry);
  }

  /// Xóa trại
  Future<int> deleteFarm(String id) {
    return (delete(farms)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Xóa tất cả trại của một công ty
  Future<int> deleteFarmsByPartner(String partnerId) {
    return (delete(farms)..where((tbl) => tbl.partnerId.equals(partnerId))).go();
  }
}
