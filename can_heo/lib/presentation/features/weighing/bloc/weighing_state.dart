import 'package:equatable/equatable.dart';

import '../../../../domain/entities/invoice.dart';

enum WeighingStatus {
  initial,
  editing,
  loading,
  success,
  failure,
}

class WeighingState extends Equatable {
  final WeighingStatus status;
  final InvoiceEntity? currentInvoice;
  final List<WeighingItemEntity> items;
  final String? errorMessage;
  
  // --- Mới: Trạng thái đầu cân ---
  final double scaleWeight;       // Số cân hiện tại từ máy
  final bool isScaleConnected;    // Trạng thái kết nối

  const WeighingState({
    this.status = WeighingStatus.initial,
    this.currentInvoice,
    this.items = const [],
    this.errorMessage,
    this.scaleWeight = 0.0,
    this.isScaleConnected = false,
  });

  factory WeighingState.initial() => const WeighingState();

  WeighingState copyWith({
    WeighingStatus? status,
    InvoiceEntity? currentInvoice,
    List<WeighingItemEntity>? items,
    String? errorMessage,
    bool clearError = false,
    double? scaleWeight,
    bool? isScaleConnected,
  }) {
    return WeighingState(
      status: status ?? this.status,
      currentInvoice: currentInvoice ?? this.currentInvoice,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      scaleWeight: scaleWeight ?? this.scaleWeight,
      isScaleConnected: isScaleConnected ?? this.isScaleConnected,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    currentInvoice, 
    items, 
    errorMessage,
    scaleWeight,
    isScaleConnected,
  ];
}