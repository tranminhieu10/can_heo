import 'package:equatable/equatable.dart';

abstract class InvoiceHistoryEvent extends Equatable {
  const InvoiceHistoryEvent();
  @override
  List<Object?> get props => [];
}

// Khởi tạo màn hình
class LoadInvoices extends InvoiceHistoryEvent {
  final int type; 
  const LoadInvoices(this.type);
  @override
  List<Object?> get props => [type];
}

// [TỐI ƯU] Sự kiện khi người dùng gõ tìm kiếm hoặc chọn ngày
class FilterInvoices extends InvoiceHistoryEvent {
  final String? keyword;
  final int? daysFilter; // null=All, 0=Today, 7=Week...

  const FilterInvoices({this.keyword, this.daysFilter});
  
  @override
  List<Object?> get props => [keyword, daysFilter];
}

class DeleteInvoice extends InvoiceHistoryEvent {
  final String id;
  const DeleteInvoice(this.id);
  @override
  List<Object?> get props => [id];
}