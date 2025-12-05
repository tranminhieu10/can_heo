import 'package:equatable/equatable.dart';

class PartnerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final bool isSupplier; // true = Trại, false = Khách
  final double currentDebt;

  const PartnerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.isSupplier,
    required this.currentDebt,
  });

  @override
  List<Object?> get props => [id, name, phone, address, isSupplier, currentDebt];
}