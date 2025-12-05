import 'package:drift/drift.dart';

@DataClassName('Partner')
class Partners extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get code => text().nullable()(); // Mã khách hàng/trại
  
  // Phân loại: true là Trại (Cung cấp), false là Khách mua (Lái buôn)
  BoolColumn get isSupplier => boolean().withDefault(const Constant(false))(); 
  
  // Tổng công nợ hiện tại (Dương: Họ nợ mình, Âm: Mình nợ họ)
  RealColumn get currentDebt => real().withDefault(const Constant(0.0))();
  
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}