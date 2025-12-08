import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/pig_types.dart';

part 'pig_types_dao.g.dart';

@DriftAccessor(tables: [PigTypes])
class PigTypesDao extends DatabaseAccessor<AppDatabase> with _$PigTypesDaoMixin {
  PigTypesDao(AppDatabase db) : super(db);

  Stream<List<PigType>> watchAllPigTypes() {
    return (select(pigTypes)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<int> insertPigType(PigTypesCompanion entry) {
    return into(pigTypes).insert(entry);
  }

  Future<bool> updatePigType(PigType entry) {
    return update(pigTypes).replace(entry);
  }

  Future<int> deletePigTypeById(String id) {
    return (delete(pigTypes)..where((t) => t.id.equals(id))).go();
  }

  Future<PigType?> getById(String id) {
    return (select(pigTypes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
