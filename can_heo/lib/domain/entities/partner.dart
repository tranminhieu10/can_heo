import 'package:equatable/equatable.dart';

class PartnerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final bool isSupplier; // true = Trại, false = Khách
  final double currentDebt; // Dương: họ nợ mình, âm: mình nợ họ

  const PartnerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.isSupplier,
    required this.currentDebt,
  });

  PartnerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    bool? isSupplier,
    double? currentDebt,
  }) {
    return PartnerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isSupplier: isSupplier ?? this.isSupplier,
      currentDebt: currentDebt ?? this.currentDebt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        isSupplier,
        currentDebt,
      ];
}
