import 'package:equatable/equatable.dart';

/// Entity đại diện cho Vật tư trong kho
class SupplyEntity extends Equatable {
  final String id;
  final String name;           // Tên vật tư
  final String? code;          // Mã vật tư
  final String? category;      // Loại (Thức ăn, Thuốc, Dụng cụ, ...)
  final String unit;           // Đơn vị (kg, bao, chai, cái, ...)
  final double quantity;       // Số lượng tồn
  final double? minQuantity;   // Số lượng tối thiểu (cảnh báo khi dưới mức này)
  final double? pricePerUnit;  // Đơn giá
  final String? supplier;      // Nhà cung cấp
  final String? note;          // Ghi chú
  final DateTime createdDate;
  final DateTime? updatedDate;

  const SupplyEntity({
    required this.id,
    required this.name,
    this.code,
    this.category,
    required this.unit,
    required this.quantity,
    this.minQuantity,
    this.pricePerUnit,
    this.supplier,
    this.note,
    required this.createdDate,
    this.updatedDate,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        category,
        unit,
        quantity,
        minQuantity,
        pricePerUnit,
        supplier,
        note,
        createdDate,
        updatedDate,
      ];

  SupplyEntity copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? unit,
    double? quantity,
    double? minQuantity,
    double? pricePerUnit,
    String? supplier,
    String? note,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return SupplyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      supplier: supplier ?? this.supplier,
      note: note ?? this.note,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

/// Entity đại diện cho giao dịch Nhập/Xuất vật tư
class SupplyTransactionEntity extends Equatable {
  final String id;
  final String supplyId;       // ID vật tư
  final String supplyName;     // Tên vật tư (để hiển thị)
  final int type;              // 0: Nhập, 1: Xuất
  final double quantity;       // Số lượng nhập/xuất
  final double? pricePerUnit;  // Đơn giá
  final double? totalAmount;   // Thành tiền
  final String? note;          // Ghi chú
  final DateTime createdDate;

  const SupplyTransactionEntity({
    required this.id,
    required this.supplyId,
    required this.supplyName,
    required this.type,
    required this.quantity,
    this.pricePerUnit,
    this.totalAmount,
    this.note,
    required this.createdDate,
  });

  @override
  List<Object?> get props => [
        id,
        supplyId,
        supplyName,
        type,
        quantity,
        pricePerUnit,
        totalAmount,
        note,
        createdDate,
      ];
}
