import '../entities/transaction.dart';

abstract class ITransactionRepository {
  // Xem toàn bộ lịch sử giao dịch
  Stream<List<TransactionEntity>> watchTransactions();
  
  // Tạo giao dịch mới (Thanh toán công nợ)
  Future<void> createTransaction(TransactionEntity transaction);
}