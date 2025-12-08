import 'package:equatable/equatable.dart';

/// 1 lần cân trong phiếu
class WeighingItemEntity extends Equatable {
  final String id;
  final int sequence; // STT
  final double weight; // kg
  final int quantity; // số con
  final DateTime time; // thời gian cân
  final String? batchNumber; // số lô heo
  final String? pigType; // loại heo

  const WeighingItemEntity({
    required this.id,
    required this.sequence,
    required this.weight,
    required this.quantity,
    required this.time,
    this.batchNumber,
    this.pigType,
  });

  WeighingItemEntity copyWith({
    String? id,
    int? sequence,
    double? weight,
    int? quantity,
    DateTime? time,
    String? batchNumber,
    String? pigType,
  }) {
    return WeighingItemEntity(
      id: id ?? this.id,
      sequence: sequence ?? this.sequence,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      time: time ?? this.time,
      batchNumber: batchNumber ?? this.batchNumber,
      pigType: pigType ?? this.pigType,
    );
  }

  @override
  List<Object?> get props => [id, sequence, weight, quantity, time, batchNumber, pigType];
}

/// Phiếu cân (header) + danh sách chi tiết (có thể trống)
class InvoiceEntity extends Equatable {
  final String id;
  final String? partnerId;
  final String? partnerName;
  final int type; // 1 = Nhập kho, 2 = Xuất chợ...
  final DateTime createdDate;

  final double totalWeight; // tổng kg
  final int totalQuantity; // tổng số con
  final double finalAmount; // thành tiền
  final String? note; // Ghi chú phiếu (số lô, nguồn nhập...)

  final List<WeighingItemEntity> details;

  const InvoiceEntity({
    required this.id,
    this.partnerId,
    this.partnerName,
    required this.type,
    required this.createdDate,
    required this.totalWeight,
    required this.totalQuantity,
    required this.finalAmount,
    this.note,
    this.details = const [],
  });

  InvoiceEntity copyWith({
    String? id,
    String? partnerId,
    String? partnerName,
    int? type,
    DateTime? createdDate,
    double? totalWeight,
    int? totalQuantity,
    double? finalAmount,
    String? note,
    List<WeighingItemEntity>? details,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      type: type ?? this.type,
      createdDate: createdDate ?? this.createdDate,
      totalWeight: totalWeight ?? this.totalWeight,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      finalAmount: finalAmount ?? this.finalAmount,
      note: note ?? this.note,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [
    id,
    partnerId,
    partnerName,
    type,
    createdDate,
    totalWeight,
    totalQuantity,
    finalAmount,
    note,
    details,
  ];
}