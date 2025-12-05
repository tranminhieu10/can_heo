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

  // QUAN TRỌNG: Tham số type phải là int để khớp với IntColumn trong DB
  Stream<List<InvoiceWithPartner>> watchInvoicesByType(int type) {
    final query = select(invoices).join([
      leftOuterJoin(partners, partners.id.equalsExp(invoices.partnerId)),
    ]);
    
    // So sánh int với int -> Hết lỗi
    query.where(invoices.type.equals(type));
    query.orderBy([OrderingTerm.desc(invoices.createdDate)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return InvoiceWithPartner(
          invoice: row.readTable(invoices),
          partner: row.readTableOrNull(partners),
        );
      }).toList();
    });
  }

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