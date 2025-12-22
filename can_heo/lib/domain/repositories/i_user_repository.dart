import '../entities/user.dart';

abstract class IUserRepository {
  Stream<List<UserEntity>> watchAllUsers();
  Future<List<UserEntity>> getAllUsers();
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> getUserByUsername(String username);
  Future<UserEntity?> authenticate(String username, String password);
  Future<void> addUser(UserEntity user);
  Future<void> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
  Future<void> updateLastLogin(String userId);
  Future<void> createDefaultAdmin();
  Future<bool> hasAnyUser();
}
