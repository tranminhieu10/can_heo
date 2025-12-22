import 'package:equatable/equatable.dart';

class CageEntity extends Equatable {
  final String id;
  final String name;
  final int? capacity;
  final String? note;
  final DateTime createdAt;

  const CageEntity({
    required this.id,
    required this.name,
    this.capacity,
    this.note,
    required this.createdAt,
  });

  CageEntity copyWith({
    String? id,
    String? name,
    int? capacity,
    String? note,
    DateTime? createdAt,
  }) {
    return CageEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, capacity, note, createdAt];
}
