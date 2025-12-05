import 'package:drift/drift.dart';
import 'invoices.dart';

// QUAN TRỌNG: Dòng này giúp Drift tạo ra class tên là "WeighingDetail" (không có Data)
@DataClassName('WeighingDetail') 
class WeighingDetails extends Table {
  // ... nội dung cũ giữ nguyên
  TextColumn get id => text()();
  TextColumn get invoiceId => text().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer()();
  RealColumn get weight => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get weighingTime => dateTime()();
  TextColumn get note => text().nullable()(); 
  
  @override
  Set<Column> get primaryKey => {id};
}