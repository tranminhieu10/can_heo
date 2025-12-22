import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/cages.dart';

part 'cages_dao.g.dart';

@DriftAccessor(tables: [Cages])
class CagesDao extends DatabaseAccessor<AppDatabase> with _$CagesDaoMixin {
  CagesDao(AppDatabase db) : super(db);

  // Theo dõi tất cả chuồng kho
  Stream<List<Cage>> watchAllCages() {
    return (select(cages)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  // Lấy tất cả chuồng kho
  Future<List<Cage>> getAllCages() {
    return (select(cages)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  // Lấy thông tin một chuồng theo ID
  Future<Cage?> getCageById(String id) {
    return (select(cages)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Thêm chuồng mới
  Future<void> insertCage(Insertable<Cage> cage) => into(cages).insert(cage);

  // Cập nhật thông tin chuồng
  Future<void> updateCage(Cage cage) =>
      (update(cages)..where((t) => t.id.equals(cage.id))).write(cage);

  // Xóa chuồng
  Future<void> deleteCage(String id) =>
      (delete(cages)..where((t) => t.id.equals(id))).go();
}
