import 'package:equatable/equatable.dart';

class FarmEntity extends Equatable {
  final String id;
  final String name;
  final String partnerId; // ID của công ty (NCC) sở hữu trại này
  final String? address;
  final String? phone;
  final String? note;
  final DateTime? createdAt;

  const FarmEntity({
    required this.id,
    required this.name,
    required this.partnerId,
    this.address,
    this.phone,
    this.note,
    this.createdAt,
  });

  FarmEntity copyWith({
    String? id,
    String? name,
    String? partnerId,
    String? address,
    String? phone,
    String? note,
    DateTime? createdAt,
  }) {
    return FarmEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerId: partnerId ?? this.partnerId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, partnerId, address, phone, note, createdAt];
}
