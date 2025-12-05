import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(AppDatabase db) : super(db);

  Stream<List<Transaction>> watchTransactionsByPartner(String partnerId) {
    return (select(transactions)
      ..where((tbl) => tbl.partnerId.equals(partnerId))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
      .watch();
  }

  Future<int> createTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }
}