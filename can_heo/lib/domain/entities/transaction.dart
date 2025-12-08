import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String? partnerId;
  final String? partnerName;
  final double amount;
  final int type;           // 0: Thu, 1: Chi
  final int paymentMethod;  // 0: Tiền mặt, 1: Chuyển khoản
  final DateTime date;
  final String? note;

  const TransactionEntity({
    required this.id,
    this.partnerId,
    this.partnerName,
    required this.amount,
    required this.type,
    this.paymentMethod = 0, // Mặc định: Tiền mặt
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        partnerId,
        partnerName,
        amount,
        type,
        paymentMethod,
        date,
        note,
      ];
}
