import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/invoices.dart';
import '../tables/partners.dart';

part 'invoices_dao.g.dart';

class InvoiceWithPartner {
  final Invoice invoice;
  final Partner? partner;

  InvoiceWithPartner({required this.invoice, this.partner});
}

@DriftAccessor(tables: [Invoices, Partners])
class InvoicesDao extends DatabaseAccessor<AppDatabase> with _$InvoicesDaoMixin {
  InvoicesDao(AppDatabase db) : super(db);

  /// [TỐI ƯU] Hàm lọc dữ liệu trực tiếp dưới SQL
  Stream<List<InvoiceWithPartner>> watchInvoicesFiltered({
    required int type,
    String? keyword,
    DateTime? fromDate,
  }) {
    // 1. Join bảng
    final query = select(invoices).join([
      leftOuterJoin(partners, partners.id.equalsExp(invoices.partnerId)),
    ]);
    
    // 2. Điều kiện cứng: Loại phiếu
    var predicate = invoices.type.equals(type);

    // 3. Điều kiện động: Từ khóa (Tìm theo tên khách HOẶC mã phiếu)
    if (keyword != null && keyword.isNotEmpty) {
      final searchStr = '%${keyword.toLowerCase()}%';
      // Lưu ý: Drift tự xử lý SQL Injection, không lo vấn đề bảo mật
      predicate = predicate & (
        partners.name.lower().like(searchStr) | 
        invoices.id.lower().like(searchStr)
      );
    }

    // 4. Điều kiện động: Thời gian (Từ ngày X đến nay)
    if (fromDate != null) {
      predicate = predicate & invoices.createdDate.isBiggerOrEqualValue(fromDate);
    }

    // 5. Áp dụng điều kiện và Sắp xếp
    query.where(predicate);
    query.orderBy([OrderingTerm.desc(invoices.createdDate)]);

    // 6. Map kết quả
    return query.watch().map((rows) {
      return rows.map((row) {
        return InvoiceWithPartner(
          invoice: row.readTable(invoices),
          partner: row.readTableOrNull(partners),
        );
      }).toList();
    });
  }

  // Giữ lại các hàm CRUD cơ bản
  Future<int> createInvoice(InvoicesCompanion entry) {
    return into(invoices).insert(entry);
  }

  Future<bool> updateInvoice(Invoice entry) {
    return update(invoices).replace(entry);
  }

  Future<int> deleteInvoice(String id) {
    return (delete(invoices)..where((tbl) => tbl.id.equals(id))).go();
  }
}