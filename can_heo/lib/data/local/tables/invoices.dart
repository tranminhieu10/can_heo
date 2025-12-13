import 'package:drift/drift.dart';
import 'partners.dart';

@DataClassName('Invoice')
class Invoices extends Table {
  TextColumn get id => text()();
  
  // Mã phiếu theo ngày (VD: 20251212-01)
  TextColumn get invoiceCode => text().nullable()();
  
  // Liên kết với bảng Partner
  TextColumn get partnerId => text().nullable().references(Partners, #id)();
  
  // Loại phiếu: Nhập Kho/Xuất Chợ... (Lưu dưới dạng index của Enum)
  IntColumn get type => integer()(); 
  
  DateTimeColumn get createdDate => dateTime()();
  
  // Các trường tổng hợp (Lấy từ ảnh)
  RealColumn get totalWeight => real().withDefault(const Constant(0.0))(); // Tổng trọng lượng
  IntColumn get totalQuantity => integer().withDefault(const Constant(0))(); // Tổng số con
  RealColumn get pricePerKg => real().withDefault(const Constant(0.0))(); // Đơn giá
  
  RealColumn get truckCost => real().withDefault(const Constant(0.0))(); // Cước xe
  RealColumn get discount => real().withDefault(const Constant(0.0))(); // Chiết khấu (nếu có)
  
  // Thành tiền = (totalWeight * pricePerKg) + truckCost - discount
  RealColumn get finalAmount => real().withDefault(const Constant(0.0))(); 
  
  // Số tiền khách đã đưa ngay lúc cân (Thanh toán trong ảnh)
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  
  TextColumn get note => text().nullable()(); // Ghi chú: Số lô, loại heo...

  @override
  Set<Column> get primaryKey => {id};
}