import 'package:equatable/equatable.dart';

// Class con chi tiết cân
class WeighingItemEntity extends Equatable {
  final String id;
  final int sequence; // STT
  final double weight; // KG
  final int quantity; // Số con
  final DateTime time;

  const WeighingItemEntity({
    required this.id,
    required this.sequence,
    required this.weight,
    required this.quantity,
    required this.time,
  });

  @override
  List<Object?> get props => [id, sequence, weight, quantity, time];
}

// Class cha phiếu cân
class InvoiceEntity extends Equatable {
  final String id;
  final String? partnerName;
  final String? partnerId;
  final int type; // Nhập Kho/Xuất Chợ...
  final DateTime createdDate;
  final double totalWeight;
  final int totalQuantity;
  final double finalAmount; // Thành tiền
  final List<WeighingItemEntity> details; // Danh sách các mã cân

  const InvoiceEntity({
    required this.id,
    this.partnerName,
    this.partnerId,
    required this.type,
    required this.createdDate,
    required this.totalWeight,
    required this.totalQuantity,
    required this.finalAmount,
    this.details = const [],
  });

  @override
  List<Object?> get props => [id, partnerId, type, createdDate, totalWeight, totalQuantity, finalAmount, details];
}