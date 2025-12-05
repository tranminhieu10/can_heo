import 'package:equatable/equatable.dart';
import '../../../../../domain/entities/invoice.dart';

abstract class WeighingEvent extends Equatable {
  const WeighingEvent();

  @override
  List<Object?> get props => [];
}

// 1. Khởi tạo phiếu mới (VD: Bắt đầu cân xe mới)
class WeighingStarted extends WeighingEvent {
  final int invoiceType; // Nhập Kho hay Xuất Chợ
  const WeighingStarted(this.invoiceType);
}

// 2. Thêm một mã cân (Mô phỏng cân xong 1 con)
class WeighingItemAdded extends WeighingEvent {
  final double weight;
  final int quantity;

  const WeighingItemAdded({required this.weight, this.quantity = 1});
}

// 3. Cập nhật thông tin phiếu (Chọn khách hàng, nhập giá...)
class WeighingInvoiceUpdated extends WeighingEvent {
  final String? partnerId;
  final double? pricePerKg;
  final double? truckCost; // Cước xe

  const WeighingInvoiceUpdated({this.partnerId, this.pricePerKg, this.truckCost});
}

// 4. Lưu phiếu vào Database
class WeighingSaved extends WeighingEvent {}