import 'package:drift/drift.dart';

/// Bảng Supplies - Lưu thông tin vật tư
class Supplies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get minQuantity => real().nullable()();
  RealColumn get pricePerUnit => real().nullable()();
  TextColumn get supplier => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdDate => dateTime()();
  DateTimeColumn get updatedDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bảng SupplyTransactions - Lưu lịch sử nhập/xuất vật tư
class SupplyTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get supplyId => text()();
  TextColumn get supplyName => text()();
  IntColumn get type => integer()(); // 0: Nhập, 1: Xuất
  RealColumn get quantity => real()();
  RealColumn get pricePerUnit => real().nullable()();
  RealColumn get totalAmount => real().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
