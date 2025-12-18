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
  final String? pigType; // Lọc theo loại heo
  final String? batchNumber; // Lọc theo số lô
  final double? minWeight; // Khối lượng tối thiểu (kg)
  final double? maxWeight; // Khối lượng tối đa (kg)
  final double? minAmount; // Giá trị tối thiểu (đ)
  final double? maxAmount; // Giá trị tối đa (đ)

  const FilterInvoices({
    this.keyword,
    this.daysFilter,
    this.pigType,
    this.batchNumber,
    this.minWeight,
    this.maxWeight,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [
        keyword,
        daysFilter,
        pigType,
        batchNumber,
        minWeight,
        maxWeight,
        minAmount,
        maxAmount,
      ];
}

class DeleteInvoice extends InvoiceHistoryEvent {
  final String id;
  const DeleteInvoice(this.id);
  @override
  List<Object?> get props => [id];
}
