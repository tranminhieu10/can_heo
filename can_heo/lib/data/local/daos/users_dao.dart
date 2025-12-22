import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  Stream<List<User>> watchAllUsers() {
    return select(users).watch();
  }

  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  Future<User?> getUserById(String id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<User?> getUserByUsername(String username) {
    return (select(users)..where((tbl) => tbl.username.equals(username))).getSingleOrNull();
  }

  Future<User?> authenticate(String username, String password) {
    return (select(users)
      ..where((tbl) => 
          tbl.username.equals(username) & 
          tbl.password.equals(password) &
          tbl.isActive.equals(true)))
      .getSingleOrNull();
  }

  Future<int> insertUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  Future<bool> updateUser(User entry) {
    return update(users).replace(entry);
  }

  Future<int> deleteUser(String id) {
    return (delete(users)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateLastLogin(String userId) async {
    await (update(users)..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(lastLogin: Value(DateTime.now())));
  }

  Future<bool> hasAnyUser() async {
    final result = await select(users).get();
    return result.isNotEmpty;
  }

  Future<void> createDefaultAdmin() async {
    final hasUsers = await hasAnyUser();
    if (!hasUsers) {
      await insertUser(UsersCompanion(
        id: Value('admin-${DateTime.now().millisecondsSinceEpoch}'),
        username: const Value('admin'),
        password: const Value('abc123'),
        displayName: const Value('Quản trị viên'),
        isAdmin: const Value(true),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
      ));
    }
  }
}
