import 'package:equatable/equatable.dart';
import '../../../../domain/entities/invoice.dart';

enum WeighingStatus { initial, loading, success, failure }

class WeighingState extends Equatable {
  final WeighingStatus status;
  final InvoiceEntity? currentInvoice; // Phiếu đang cân dở
  final List<WeighingItemEntity> items; // Danh sách các mã cân trong bảng
  final String? errorMessage;

  const WeighingState({
    this.status = WeighingStatus.initial,
    this.currentInvoice,
    this.items = const [],
    this.errorMessage,
  });

  // Hàm copyWith để tạo state mới từ state cũ (giữ nguyên các trường không đổi)
  WeighingState copyWith({
    WeighingStatus? status,
    InvoiceEntity? currentInvoice,
    List<WeighingItemEntity>? items,
    String? errorMessage,
  }) {
    return WeighingState(
      status: status ?? this.status,
      currentInvoice: currentInvoice ?? this.currentInvoice,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, currentInvoice, items, errorMessage];
}