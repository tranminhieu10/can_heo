import 'package:drift/drift.dart';
import 'partners.dart';
import 'invoices.dart';

@DataClassName('Transaction')
class Transactions extends Table {
  TextColumn get id => text()();

  // Đối tác – không cho null, nếu giao dịch vãng lai bạn có thể map về 1 partner “Khách lẻ”
  TextColumn get partnerId => text().references(Partners, #id)();

  // Hóa đơn liên kết (nếu có)
  TextColumn get invoiceId => text().nullable().references(Invoices, #id)();

  // Số tiền giao dịch
  RealColumn get amount => real()();

  // Loại giao dịch: 0 = Thu, 1 = Chi
  IntColumn get type => integer()();

  // Phương thức thanh toán: 0 = Tiền mặt, 1 = Chuyển khoản
  IntColumn get paymentMethod =>
      integer().withDefault(const Constant(0))(); // default: Cash

  // Ngày giờ giao dịch
  DateTimeColumn get transactionDate => dateTime()();

  // Ghi chú (nếu có)
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
