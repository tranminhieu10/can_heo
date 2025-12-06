import 'package:equatable/equatable.dart';

abstract class InvoiceHistoryEvent extends Equatable {
  const InvoiceHistoryEvent();
  @override
  List<Object> get props => [];
}

// Sự kiện: Yêu cầu tải danh sách phiếu
class LoadInvoices extends InvoiceHistoryEvent {
  final int type; // 2 = Xuất Chợ, 1 = Nhập Kho...
  const LoadInvoices(this.type);
}

// Sự kiện: Xóa phiếu (Dự phòng cho tương lai)
class DeleteInvoice extends InvoiceHistoryEvent {
  final String id;
  const DeleteInvoice(this.id);
}