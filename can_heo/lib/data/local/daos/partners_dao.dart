import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/partners.dart';

part 'partners_dao.g.dart';

@DriftAccessor(tables: [Partners])
class PartnersDao extends DatabaseAccessor<AppDatabase> with _$PartnersDaoMixin {
  PartnersDao(AppDatabase db) : super(db);

  Stream<List<Partner>> watchAllPartners() {
    return select(partners).watch();
  }

  Stream<List<Partner>> watchPartnersByType(bool isSupplier) {
    return (select(partners)..where((tbl) => tbl.isSupplier.equals(isSupplier))).watch();
  }

  Future<List<Partner>> findPartners(String query) {
    return (select(partners)
      ..where((tbl) => tbl.name.contains(query) | tbl.phone.contains(query)))
      .get();
  }

  Future<Partner?> getPartnerById(String id) {
    return (select(partners)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPartner(PartnersCompanion entry) {
    return into(partners).insert(entry);
  }

  Future<bool> updatePartner(Partner entry) {
    return update(partners).replace(entry);
  }

  Future<void> updateDebt(String partnerId, double amount) async {
    final partner = await getPartnerById(partnerId);
    if (partner != null) {
      final newDebt = partner.currentDebt + amount;
      
      // Sử dụng PartnersCompanion để chỉ update 2 trường cần thiết
      final companion = PartnersCompanion(
        id: Value(partnerId), // Cần ID để xác định dòng update
        currentDebt: Value(newDebt),
        lastUpdated: Value(DateTime.now()), 
      );

      // Dùng update(partners).replace() nếu có object đầy đủ, 
      // hoặc dùng logic dưới đây để update từng phần:
      await (update(partners)..where((tbl) => tbl.id.equals(partnerId)))
          .write(companion);
    }
  }
}