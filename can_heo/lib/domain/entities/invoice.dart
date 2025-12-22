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
  final String? invoiceCode; // Mã phiếu theo ngày (VD: 20251212-01)
  final String? partnerId;
  final String? partnerName;
  final String? cageId; // ID chuồng (cho phiếu nhập kho)
  final int type; // 0 = Nhập kho, 2 = Xuất chợ...
  final DateTime createdDate;

  final double totalWeight; // tổng kg (TL cân)
  final int totalQuantity; // tổng số con
  
  // Thông tin giá & tính tiền
  final double pricePerKg; // Đơn giá (đ/kg)
  final double deduction; // Trừ hao (kg)
  final double discount; // Chiết khấu (đ)
  final double finalAmount; // Thực thu = (totalWeight - deduction) * pricePerKg - discount
  
  // Số tiền đã thanh toán
  final double paidAmount;
  
  final String? note; // Ghi chú phiếu (số lô, nguồn nhập...)

  final List<WeighingItemEntity> details;

  const InvoiceEntity({
    required this.id,
    this.invoiceCode,
    this.partnerId,
    this.partnerName,
    this.cageId,
    required this.type,
    required this.createdDate,
    required this.totalWeight,
    required this.totalQuantity,
    this.pricePerKg = 0,
    this.deduction = 0,
    this.discount = 0,
    required this.finalAmount,
    this.paidAmount = 0,
    this.note,
    this.details = const [],
  });

  // Computed properties
  double get netWeight => (totalWeight - deduction).clamp(0, double.infinity);
  double get subtotal => netWeight * pricePerKg;
  double get remainingAmount => (finalAmount - paidAmount).clamp(0, double.infinity);

  InvoiceEntity copyWith({
    String? id,
    String? invoiceCode,
    String? partnerId,
    String? partnerName,
    String? cageId,
    int? type,
    DateTime? createdDate,
    double? totalWeight,
    int? totalQuantity,
    double? pricePerKg,
    double? deduction,
    double? discount,
    double? finalAmount,
    double? paidAmount,
    String? note,
    List<WeighingItemEntity>? details,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceCode: invoiceCode ?? this.invoiceCode,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      cageId: cageId ?? this.cageId,
      type: type ?? this.type,
      createdDate: createdDate ?? this.createdDate,
      totalWeight: totalWeight ?? this.totalWeight,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      deduction: deduction ?? this.deduction,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [
    id,
    invoiceCode,
    partnerId,
    partnerName,
    cageId,
    type,
    createdDate,
    totalWeight,
    totalQuantity,
    pricePerKg,
    deduction,
    discount,
    finalAmount,
    paidAmount,
    note,
    details,
  ];
}