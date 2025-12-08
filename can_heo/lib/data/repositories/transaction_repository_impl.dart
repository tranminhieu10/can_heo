import 'package:drift/drift.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../local/database.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    // Join bảng Transactions với Partners để lấy tên người giao dịch
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.partners,
        _db.partners.id.equalsExp(_db.transactions.partnerId),
      ),
    ]);

    // Sắp xếp ngày mới nhất lên đầu
    query.orderBy([
      OrderingTerm.desc(_db.transactions.transactionDate),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        // Dòng giao dịch
        final tx = row.readTable(_db.transactions);
        // Đối tác (có thể null nếu là giao dịch vãng lai)
        final partner = row.readTableOrNull(_db.partners);

        return TransactionEntity(
          id: tx.id,
          partnerId: tx.partnerId,
          partnerName: partner?.name ?? 'Giao dịch vãng lai',
          amount: tx.amount,
          type: tx.type,
          paymentMethod: tx.paymentMethod,     // cột mới
          date: tx.transactionDate,
          note: tx.note,
        );
      }).toList();
    });
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    return _db.transaction(() async {
      // 1. Thêm dòng giao dịch mới vào DB
      await _db.transactionsDao.createTransaction(
        TransactionsCompanion(
          id: Value(transaction.id),
          partnerId: Value(transaction.partnerId ?? ''),
          // Nếu sau này có link với hóa đơn thì set invoiceId ở đây
          amount: Value(transaction.amount),
          type: Value(transaction.type),
          paymentMethod: Value(transaction.paymentMethod),
          transactionDate: Value(transaction.date),
          note: Value(transaction.note),
        ),
      );

      // 2. Cập nhật công nợ cho đối tác (nếu có chọn đối tác)
      if (transaction.partnerId != null) {
        // Ở màn này đang là thanh toán công nợ => trả tiền => giảm dư nợ
        final double debtAdjustment = -transaction.amount;

        await _db.partnersDao
            .updateDebt(transaction.partnerId!, debtAdjustment);
      }
    });
  }
}
