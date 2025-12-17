import 'package:drift/drift.dart';
import '../../domain/entities/farm.dart';
import '../../domain/repositories/i_farm_repository.dart';
import '../local/database.dart';

class FarmRepositoryImpl implements IFarmRepository {
  final AppDatabase _db;

  FarmRepositoryImpl(this._db);

  @override
  Stream<List<FarmEntity>> watchAllFarms() {
    return _db.farmsDao.watchAllFarms().map((dtos) {
      return dtos.map((dto) => FarmEntity(
        id: dto.id,
        name: dto.name,
        partnerId: dto.partnerId,
        address: dto.address,
        phone: dto.phone,
        note: dto.note,
        createdAt: dto.createdAt,
      )).toList();
    });
  }

  @override
  Stream<List<FarmEntity>> watchFarmsByPartner(String partnerId) {
    return _db.farmsDao.watchFarmsByPartner(partnerId).map((dtos) {
      return dtos.map((dto) => FarmEntity(
        id: dto.id,
        name: dto.name,
        partnerId: dto.partnerId,
        address: dto.address,
        phone: dto.phone,
        note: dto.note,
        createdAt: dto.createdAt,
      )).toList();
    });
  }

  @override
  Future<FarmEntity?> getFarmById(String id) async {
    final dto = await _db.farmsDao.getFarmById(id);
    if (dto == null) return null;
    return FarmEntity(
      id: dto.id,
      name: dto.name,
      partnerId: dto.partnerId,
      address: dto.address,
      phone: dto.phone,
      note: dto.note,
      createdAt: dto.createdAt,
    );
  }

  @override
  Future<void> addFarm(FarmEntity farm) async {
    await _db.farmsDao.insertFarm(FarmsCompanion(
      id: Value(farm.id),
      name: Value(farm.name),
      partnerId: Value(farm.partnerId),
      address: Value(farm.address),
      phone: Value(farm.phone),
      note: Value(farm.note),
      createdAt: Value(farm.createdAt ?? DateTime.now()),
    ));
  }

  @override
  Future<void> updateFarm(FarmEntity farm) async {
    await _db.farmsDao.updateFarm(Farm(
      id: farm.id,
      name: farm.name,
      partnerId: farm.partnerId,
      address: farm.address,
      phone: farm.phone,
      note: farm.note,
      createdAt: farm.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Future<void> deleteFarm(String id) async {
    await _db.farmsDao.deleteFarm(id);
  }
}
