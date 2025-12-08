import 'package:equatable/equatable.dart';

abstract class WeighingEvent extends Equatable {
  const WeighingEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu 1 phiếu mới
/// [invoiceType] : 1 = Nhập kho, 2 = Xuất chợ...
class WeighingStarted extends WeighingEvent {
  final int invoiceType;

  const WeighingStarted(this.invoiceType);

  @override
  List<Object?> get props => [invoiceType];
}

/// Thêm 1 lần cân vào phiếu
class WeighingItemAdded extends WeighingEvent {
  final double weight;
  final int quantity;
  final String? batchNumber; // Mới: số lô
  final String? pigType; // Mới: loại heo

  const WeighingItemAdded({
    required this.weight,
    this.quantity = 1,
    this.batchNumber,
    this.pigType,
  });

  @override
  List<Object?> get props => [weight, quantity, batchNumber, pigType];
}

/// Xoá 1 lần cân
class WeighingItemRemoved extends WeighingEvent {
  final String itemId;

  const WeighingItemRemoved(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Cập nhật thông tin phiếu (khách, giá, cước)
class WeighingInvoiceUpdated extends WeighingEvent {
  final String? partnerId;
  final String? partnerName;
  final double? pricePerKg;
  final double? truckCost;
  final String? note;

  const WeighingInvoiceUpdated({
    this.partnerId,
    this.partnerName,
    this.pricePerKg,
    this.truckCost,
    this.note,
  });

  @override
  List<Object?> get props => [partnerId, partnerName, pricePerKg, truckCost, note];
}

/// Lưu phiếu xuống DB
class WeighingSaved extends WeighingEvent {
  const WeighingSaved();
}

/// [INTERNAL] Sự kiện nội bộ: Khi Bloc nhận được dữ liệu từ Stream của ScaleService
class WeighingScaleDataReceived extends WeighingEvent {
  final double weight;
  final bool isConnected;

  const WeighingScaleDataReceived({
    required this.weight,
    required this.isConnected,
  });

  @override
  List<Object?> get props => [weight, isConnected];
}