import 'package:drift/drift.dart'; 
import '../../domain/entities/partner.dart';
import '../../domain/repositories/i_partner_repository.dart';
import '../local/database.dart'; 

class PartnerRepositoryImpl implements IPartnerRepository {
  final AppDatabase _db;

  PartnerRepositoryImpl(this._db);

  @override
  Stream<List<PartnerEntity>> watchPartners(bool isSupplier) {
    return _db.partnersDao.watchPartnersByType(isSupplier).map((dtos) {
      return dtos.map((dto) => PartnerEntity(
        id: dto.id,
        name: dto.name,
        phone: dto.phone,
        address: dto.address,
        isSupplier: dto.isSupplier,
        currentDebt: dto.currentDebt,
      )).toList();
    });
  }

  @override
  Future<void> addPartner(PartnerEntity partner) async {
    await _db.partnersDao.insertPartner(PartnersCompanion(
      id: Value(partner.id),
      name: Value(partner.name),
      phone: Value(partner.phone),
      address: Value(partner.address),
      isSupplier: Value(partner.isSupplier),
      currentDebt: Value(partner.currentDebt),
      lastUpdated: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> updatePartner(PartnerEntity partner) async {
    await _db.partnersDao.updatePartner(Partner(
      id: partner.id,
      name: partner.name,
      phone: partner.phone,
      address: partner.address,
      isSupplier: partner.isSupplier,
      currentDebt: partner.currentDebt,
      lastUpdated: DateTime.now(),
      code: null, 
    ));
  }

  @override
  Future<void> updateDebt(String partnerId, double amount) async {
    await _db.partnersDao.updateDebt(partnerId, amount);
  }

  // Mới: Xóa đối tác
  @override
  Future<void> deletePartner(String id) async {
    await (_db.delete(_db.partners)..where((tbl) => tbl.id.equals(id))).go();
  }
}