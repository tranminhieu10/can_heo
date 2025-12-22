import 'package:drift/drift.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../local/database.dart';

class UserRepositoryImpl implements IUserRepository {
  final AppDatabase _db;

  UserRepositoryImpl(this._db);

  @override
  Stream<List<UserEntity>> watchAllUsers() {
    return _db.usersDao.watchAllUsers().map((dtos) {
      return dtos.map((dto) => UserEntity(
        id: dto.id,
        username: dto.username,
        password: dto.password,
        displayName: dto.displayName,
        isAdmin: dto.isAdmin,
        isActive: dto.isActive,
        createdAt: dto.createdAt,
        lastLogin: dto.lastLogin,
      )).toList();
    });
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final dtos = await _db.usersDao.getAllUsers();
    return dtos.map((dto) => UserEntity(
      id: dto.id,
      username: dto.username,
      password: dto.password,
      displayName: dto.displayName,
      isAdmin: dto.isAdmin,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      lastLogin: dto.lastLogin,
    )).toList();
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    final dto = await _db.usersDao.getUserById(id);
    if (dto == null) return null;
    return UserEntity(
      id: dto.id,
      username: dto.username,
      password: dto.password,
      displayName: dto.displayName,
      isAdmin: dto.isAdmin,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      lastLogin: dto.lastLogin,
    );
  }

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    final dto = await _db.usersDao.getUserByUsername(username);
    if (dto == null) return null;
    return UserEntity(
      id: dto.id,
      username: dto.username,
      password: dto.password,
      displayName: dto.displayName,
      isAdmin: dto.isAdmin,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      lastLogin: dto.lastLogin,
    );
  }

  @override
  Future<UserEntity?> authenticate(String username, String password) async {
    final dto = await _db.usersDao.authenticate(username, password);
    if (dto == null) return null;
    await _db.usersDao.updateLastLogin(dto.id);
    return UserEntity(
      id: dto.id,
      username: dto.username,
      password: dto.password,
      displayName: dto.displayName,
      isAdmin: dto.isAdmin,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      lastLogin: DateTime.now(),
    );
  }

  @override
  Future<void> addUser(UserEntity user) async {
    await _db.usersDao.insertUser(UsersCompanion(
      id: Value(user.id),
      username: Value(user.username),
      password: Value(user.password),
      displayName: Value(user.displayName),
      isAdmin: Value(user.isAdmin),
      isActive: Value(user.isActive),
      createdAt: Value(user.createdAt),
    ));
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    await _db.usersDao.updateUser(User(
      id: user.id,
      username: user.username,
      password: user.password,
      displayName: user.displayName,
      isAdmin: user.isAdmin,
      isActive: user.isActive,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin,
    ));
  }

  @override
  Future<void> deleteUser(String id) async {
    await _db.usersDao.deleteUser(id);
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    await _db.usersDao.updateLastLogin(userId);
  }

  @override
  Future<void> createDefaultAdmin() async {
    await _db.usersDao.createDefaultAdmin();
  }

  @override
  Future<bool> hasAnyUser() async {
    return await _db.usersDao.hasAnyUser();
  }
}
