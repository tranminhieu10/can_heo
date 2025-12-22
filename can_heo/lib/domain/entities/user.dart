import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;
  final String? displayName;
  final bool isAdmin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.username,
    required this.password,
    this.displayName,
    required this.isAdmin,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? password,
    String? displayName,
    bool? isAdmin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  String get displayText => displayName ?? username;

  @override
  List<Object?> get props => [
        id,
        username,
        password,
        displayName,
        isAdmin,
        isActive,
        createdAt,
        lastLogin,
      ];
}
