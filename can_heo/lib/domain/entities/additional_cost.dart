import 'package:equatable/equatable.dart';

/// Chi phí khác khi nhập hàng
class AdditionalCost extends Equatable {
  final String id;
  final String label; // Tên chi phí (VD: "Cước xe", "Lợn chết")
  final double amount; // Thành tiền
  final int? quantity; // Số lượng (optional - cho lợn chết)
  final double? weight; // Cân nặng (optional - cho lợn chết)
  final String? note; // Ghi chú

  const AdditionalCost({
    required this.id,
    required this.label,
    required this.amount,
    this.quantity,
    this.weight,
    this.note,
  });

  AdditionalCost copyWith({
    String? id,
    String? label,
    double? amount,
    int? quantity,
    double? weight,
    String? note,
  }) {
    return AdditionalCost(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, label, amount, quantity, weight, note];
}
