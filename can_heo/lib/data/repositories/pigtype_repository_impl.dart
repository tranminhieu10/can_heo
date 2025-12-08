import 'package:drift/drift.dart';

import '../../domain/entities/pig_type.dart';
import '../../domain/repositories/i_pigtype_repository.dart';
import '../local/database.dart';

class PigTypeRepositoryImpl implements IPigTypeRepository {
  final AppDatabase _db;

  PigTypeRepositoryImpl(this._db);

  @override
  Stream<List<PigTypeEntity>> watchPigTypes() {
    return _db.pigTypesDao.watchAllPigTypes().map((rows) => rows.map((r) => PigTypeEntity(
          id: r.id,
          name: r.name,
          description: r.description,
          createdAt: r.createdAt,
        )).toList());
  }

  @override
  Future<void> addPigType(PigTypeEntity e) async {
    await _db.pigTypesDao.insertPigType(PigTypesCompanion(
      id: Value(e.id),
      name: Value(e.name),
      description: Value(e.description),
      createdAt: Value(e.createdAt),
    ));
  }

  @override
  Future<void> updatePigType(PigTypeEntity e) async {
    await _db.pigTypesDao.updatePigType(PigType(
      id: e.id,
      name: e.name,
      description: e.description,
      createdAt: e.createdAt,
    ));
  }

  @override
  Future<void> deletePigType(String id) async {
    await _db.pigTypesDao.deletePigTypeById(id);
  }
}
