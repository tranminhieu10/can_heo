import 'package:drift/drift.dart';

import '../../domain/entities/cage.dart';
import '../../domain/repositories/i_cage_repository.dart';
import '../local/database.dart';

class CageRepositoryImpl implements ICageRepository {
  final AppDatabase _db;

  CageRepositoryImpl(this._db);

  @override
  Stream<List<CageEntity>> watchAllCages() {
    return _db.cagesDao.watchAllCages().map(
          (cages) => cages
              .map((c) => CageEntity(
                    id: c.id,
                    name: c.name,
                    capacity: c.capacity,
                    note: c.note,
                    createdAt: c.createdAt,
                  ))
              .toList(),
        );
  }

  @override
  Future<List<CageEntity>> getAllCages() async {
    final cages = await _db.cagesDao.getAllCages();
    return cages
        .map((c) => CageEntity(
              id: c.id,
              name: c.name,
              capacity: c.capacity,
              note: c.note,
              createdAt: c.createdAt,
            ))
        .toList();
  }

  @override
  Future<CageEntity?> getCageById(String id) async {
    final cage = await _db.cagesDao.getCageById(id);
    if (cage == null) return null;
    return CageEntity(
      id: cage.id,
      name: cage.name,
      capacity: cage.capacity,
      note: cage.note,
      createdAt: cage.createdAt,
    );
  }

  @override
  Future<void> addCage(CageEntity cage) async {
    await _db.cagesDao.insertCage(
      CagesCompanion.insert(
        id: cage.id,
        name: cage.name,
        capacity: Value(cage.capacity),
        note: Value(cage.note),
        createdAt: Value(cage.createdAt),
      ),
    );
  }

  @override
  Future<void> updateCage(CageEntity cage) async {
    await _db.cagesDao.updateCage(
      Cage(
        id: cage.id,
        name: cage.name,
        capacity: cage.capacity,
        note: cage.note,
        createdAt: cage.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteCage(String id) async {
    await _db.cagesDao.deleteCage(id);
  }
}
