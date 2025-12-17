import 'package:drift/drift.dart';

@DataClassName('Farm')
class Farms extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 100)(); // Tên trại
  TextColumn get partnerId => text()(); // ID của công ty (NCC) sở hữu trại này
  TextColumn get address => text().nullable()(); // Địa chỉ trại
  TextColumn get phone => text().nullable()(); // SĐT liên hệ trại
  TextColumn get note => text().nullable()(); // Ghi chú
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
