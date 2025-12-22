import 'package:drift/drift.dart';

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get password => text().withLength(min: 1, max: 100)();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastLogin => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
