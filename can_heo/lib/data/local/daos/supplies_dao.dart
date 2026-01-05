import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/supplies.dart';

part 'supplies_dao.g.dart';

@DriftAccessor(tables: [Supplies, SupplyTransactions])
class SuppliesDao extends DatabaseAccessor<AppDatabase> with _$SuppliesDaoMixin {
  SuppliesDao(AppDatabase db) : super(db);

  // ==================== SUPPLIES ====================

  /// Lấy tất cả vật tư
  Future<List<Supply>> getAllSupplies() {
    return (select(supplies)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  /// Stream theo dõi vật tư
  Stream<List<Supply>> watchAllSupplies() {
    return (select(supplies)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  /// Lấy vật tư theo ID
  Future<Supply?> getSupplyById(String id) {
    return (select(supplies)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Tạo vật tư mới
  Future<int> insertSupply(SuppliesCompanion entry) {
    return into(supplies).insert(entry);
  }

  /// Cập nhật vật tư
  Future<bool> updateSupply(Supply entry) {
    return update(supplies).replace(entry);
  }

  /// Xóa vật tư
  Future<int> deleteSupplyById(String id) {
    return (delete(supplies)..where((t) => t.id.equals(id))).go();
  }

  /// Cập nhật số lượng vật tư
  Future<void> updateQuantity(String id, double newQuantity) async {
    await (update(supplies)..where((t) => t.id.equals(id))).write(
      SuppliesCompanion(
        quantity: Value(newQuantity),
        updatedDate: Value(DateTime.now()),
      ),
    );
  }

  /// Lấy vật tư sắp hết (dưới mức tối thiểu)
  Future<List<Supply>> getLowStockSupplies() async {
    final all = await getAllSupplies();
    return all.where((s) {
      if (s.minQuantity == null) return false;
      return s.quantity < s.minQuantity!;
    }).toList();
  }

  // ==================== TRANSACTIONS ====================

  /// Lấy lịch sử giao dịch của vật tư
  Future<List<SupplyTransaction>> getTransactionHistory(String supplyId) {
    return (select(supplyTransactions)
          ..where((t) => t.supplyId.equals(supplyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdDate)]))
        .get();
  }

  /// Stream theo dõi lịch sử giao dịch
  Stream<List<SupplyTransaction>> watchTransactionHistory({String? supplyId}) {
    final query = select(supplyTransactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdDate)]);
    
    if (supplyId != null) {
      query.where((t) => t.supplyId.equals(supplyId));
    }
    
    return query.watch();
  }

  /// Thêm giao dịch
  Future<int> insertTransaction(SupplyTransactionsCompanion entry) {
    return into(supplyTransactions).insert(entry);
  }

  /// Xóa giao dịch theo supply ID
  Future<int> deleteTransactionsBySupplyId(String supplyId) {
    return (delete(supplyTransactions)..where((t) => t.supplyId.equals(supplyId))).go();
  }
}
