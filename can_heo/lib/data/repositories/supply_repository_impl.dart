import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/supply.dart';
import '../../domain/repositories/i_supply_repository.dart';
import '../local/database.dart';

class SupplyRepositoryImpl implements ISupplyRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SupplyRepositoryImpl(this._db);

  @override
  Future<List<SupplyEntity>> getAllSupplies() async {
    final rows = await _db.suppliesDao.getAllSupplies();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<SupplyEntity>> watchSupplies() {
    return _db.suppliesDao.watchAllSupplies().map(
      (rows) => rows.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<SupplyEntity?> getSupplyById(String id) async {
    final row = await _db.suppliesDao.getSupplyById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> createSupply(SupplyEntity supply) async {
    await _db.suppliesDao.insertSupply(SuppliesCompanion(
      id: Value(supply.id),
      name: Value(supply.name),
      code: Value(supply.code),
      category: Value(supply.category),
      unit: Value(supply.unit),
      quantity: Value(supply.quantity),
      minQuantity: Value(supply.minQuantity),
      pricePerUnit: Value(supply.pricePerUnit),
      supplier: Value(supply.supplier),
      note: Value(supply.note),
      createdDate: Value(supply.createdDate),
      updatedDate: Value(supply.updatedDate),
    ));
  }

  @override
  Future<void> updateSupply(SupplyEntity supply) async {
    await _db.suppliesDao.updateSupply(Supply(
      id: supply.id,
      name: supply.name,
      code: supply.code,
      category: supply.category,
      unit: supply.unit,
      quantity: supply.quantity,
      minQuantity: supply.minQuantity,
      pricePerUnit: supply.pricePerUnit,
      supplier: supply.supplier,
      note: supply.note,
      createdDate: supply.createdDate,
      updatedDate: supply.updatedDate ?? DateTime.now(),
    ));
  }

  @override
  Future<void> deleteSupply(String id) async {
    // Xóa lịch sử giao dịch trước
    await _db.suppliesDao.deleteTransactionsBySupplyId(id);
    await _db.suppliesDao.deleteSupplyById(id);
  }

  @override
  Future<void> importSupply(String supplyId, double quantity, {double? pricePerUnit, String? note}) async {
    final supply = await _db.suppliesDao.getSupplyById(supplyId);
    if (supply == null) return;

    // Cập nhật số lượng
    final newQuantity = supply.quantity + quantity;
    await _db.suppliesDao.updateQuantity(supplyId, newQuantity);

    // Lưu giao dịch
    await _db.suppliesDao.insertTransaction(SupplyTransactionsCompanion(
      id: Value(_uuid.v4()),
      supplyId: Value(supplyId),
      supplyName: Value(supply.name),
      type: const Value(0), // Nhập
      quantity: Value(quantity),
      pricePerUnit: Value(pricePerUnit ?? supply.pricePerUnit),
      totalAmount: Value(quantity * (pricePerUnit ?? supply.pricePerUnit ?? 0)),
      note: Value(note),
      createdDate: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> exportSupply(String supplyId, double quantity, {String? note}) async {
    final supply = await _db.suppliesDao.getSupplyById(supplyId);
    if (supply == null) return;

    // Cập nhật số lượng
    final newQuantity = supply.quantity - quantity;
    await _db.suppliesDao.updateQuantity(supplyId, newQuantity < 0 ? 0 : newQuantity);

    // Lưu giao dịch
    await _db.suppliesDao.insertTransaction(SupplyTransactionsCompanion(
      id: Value(_uuid.v4()),
      supplyId: Value(supplyId),
      supplyName: Value(supply.name),
      type: const Value(1), // Xuất
      quantity: Value(quantity),
      pricePerUnit: Value(supply.pricePerUnit),
      totalAmount: Value(quantity * (supply.pricePerUnit ?? 0)),
      note: Value(note),
      createdDate: Value(DateTime.now()),
    ));
  }

  @override
  Future<List<SupplyTransactionEntity>> getTransactionHistory(String supplyId) async {
    final rows = await _db.suppliesDao.getTransactionHistory(supplyId);
    return rows.map(_mapTransactionToEntity).toList();
  }

  @override
  Stream<List<SupplyTransactionEntity>> watchTransactionHistory({String? supplyId}) {
    return _db.suppliesDao.watchTransactionHistory(supplyId: supplyId).map(
      (rows) => rows.map(_mapTransactionToEntity).toList(),
    );
  }

  @override
  Future<List<SupplyEntity>> getLowStockSupplies() async {
    final rows = await _db.suppliesDao.getLowStockSupplies();
    return rows.map(_mapToEntity).toList();
  }

  // Helper methods
  SupplyEntity _mapToEntity(Supply row) {
    return SupplyEntity(
      id: row.id,
      name: row.name,
      code: row.code,
      category: row.category,
      unit: row.unit,
      quantity: row.quantity,
      minQuantity: row.minQuantity,
      pricePerUnit: row.pricePerUnit,
      supplier: row.supplier,
      note: row.note,
      createdDate: row.createdDate,
      updatedDate: row.updatedDate,
    );
  }

  SupplyTransactionEntity _mapTransactionToEntity(SupplyTransaction row) {
    return SupplyTransactionEntity(
      id: row.id,
      supplyId: row.supplyId,
      supplyName: row.supplyName,
      type: row.type,
      quantity: row.quantity,
      pricePerUnit: row.pricePerUnit,
      totalAmount: row.totalAmount,
      note: row.note,
      createdDate: row.createdDate,
    );
  }
}
