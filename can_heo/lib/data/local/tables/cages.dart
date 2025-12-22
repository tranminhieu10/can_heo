import 'package:drift/drift.dart';

@DataClassName('Cage')
class Cages extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 100)(); // Tên chuồng (VD: "Chuồng A1", "Chuồng B2")
  IntColumn get capacity => integer().nullable()(); // Sức chứa (số lượng heo tối đa)
  TextColumn get note => text().nullable()(); // Ghi chú
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
