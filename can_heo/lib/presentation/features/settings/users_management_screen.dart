import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/i_user_repository.dart';
import '../../../injection_container.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final _userRepository = sl<IUserRepository>();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm người dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Quyền Admin'),
                  subtitle: const Text('Có thể quản lý người dùng khác'),
                  value: isAdmin,
                  onChanged: (value) {
                    setDialogState(() => isAdmin = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Check if username exists
                final existing = await _userRepository.getUserByUsername(
                    usernameController.text.trim());
                if (existing != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tên đăng nhập đã tồn tại'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final newUser = UserEntity(
                  id: 'user-${DateTime.now().millisecondsSinceEpoch}',
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                  displayName: displayNameController.text.trim().isNotEmpty
                      ? displayNameController.text.trim()
                      : null,
                  isAdmin: isAdmin,
                  isActive: true,
                  createdAt: DateTime.now(),
                );

                await _userRepository.addUser(newUser);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã thêm người dùng'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserEntity user) {
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController(text: user.password);
    final displayNameController =
        TextEditingController(text: user.displayName ?? '');
    bool isAdmin = user.isAdmin;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sửa người dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Để trống nếu không muốn đổi',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Quyền Admin'),
                  value: isAdmin,
                  onChanged: (value) {
                    setDialogState(() => isAdmin = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Đang hoạt động'),
                  subtitle: const Text('Tắt nếu muốn vô hiệu hóa tài khoản'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên đăng nhập'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Check if username changed and exists
                if (usernameController.text.trim() != user.username) {
                  final existing = await _userRepository.getUserByUsername(
                      usernameController.text.trim());
                  if (existing != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tên đăng nhập đã tồn tại'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }

                final updatedUser = user.copyWith(
                  username: usernameController.text.trim(),
                  password: passwordController.text.isNotEmpty
                      ? passwordController.text
                      : user.password,
                  displayName: displayNameController.text.trim().isNotEmpty
                      ? displayNameController.text.trim()
                      : null,
                  isAdmin: isAdmin,
                  isActive: isActive,
                );

                await _userRepository.updateUser(updatedUser);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã cập nhật người dùng'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa người dùng "${user.displayText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _userRepository.deleteUser(user.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã xóa người dùng'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Thêm người dùng',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<UserEntity>>(
        stream: _userRepository.watchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có người dùng nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Thêm người dùng'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        user.isAdmin ? Colors.orange[100] : Colors.blue[100],
                    child: Icon(
                      user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: user.isAdmin ? Colors.orange[700] : Colors.blue[700],
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Vô hiệu',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      if (user.isAdmin)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tài khoản: ${user.username}'),
                      if (user.lastLogin != null)
                        Text(
                          'Đăng nhập cuối: ${_dateFormat.format(user.lastLogin!)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditUserDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteUser(user),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
