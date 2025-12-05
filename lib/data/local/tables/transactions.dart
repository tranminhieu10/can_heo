import 'package:drift/drift.dart';
import 'partners.dart';
import 'invoices.dart';

@DataClassName('Transaction')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get partnerId => text().references(Partners, #id)();
  
  // Có thể gắn với Invoice hoặc không (nếu là trả nợ cũ thì field này null)
  TextColumn get invoiceId => text().nullable().references(Invoices, #id)();
  
  RealColumn get amount => real()(); // Số tiền
  IntColumn get type => integer()(); // Payment, Refund... (Enum index)
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}