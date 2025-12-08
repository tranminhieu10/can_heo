import '../entities/pig_type.dart';

abstract class IPigTypeRepository {
  Stream<List<PigTypeEntity>> watchPigTypes();

  Future<void> addPigType(PigTypeEntity e);
  Future<void> updatePigType(PigTypeEntity e);
  Future<void> deletePigType(String id);
}
