import 'package:drift/drift.dart'; // Để dùng Value()
import '../../domain/entities/partner.dart';
import '../../domain/repositories/i_partner_repository.dart';
import '../local/database.dart'; // Import DB gốc

class PartnerRepositoryImpl implements IPartnerRepository {
  final AppDatabase _db;

  PartnerRepositoryImpl(this._db);

  @override
  Stream<List<PartnerEntity>> watchPartners(bool isSupplier) {
    // Gọi xuống DAO và chuyển đổi (map) dữ liệu
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
    // Chuyển từ Entity -> DB Object (Companion)
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
    // Lưu ý: Drift generated class tên là 'Partner' (trùng tên Entity), 
    // nên ta dùng alias hoặc khởi tạo object đầy đủ.
    await _db.partnersDao.updatePartner(Partner(
      id: partner.id,
      name: partner.name,
      phone: partner.phone,
      address: partner.address,
      isSupplier: partner.isSupplier,
      currentDebt: partner.currentDebt,
      lastUpdated: DateTime.now(),
      code: null, // Nếu có mã code thì map vào đây
    ));
  }

  @override
  Future<void> updateDebt(String partnerId, double amount) async {
    await _db.partnersDao.updateDebt(partnerId, amount);
  }
}