import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/pig_type.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../injection_container.dart';

class PigTypesScreen extends StatefulWidget {
  const PigTypesScreen({super.key});

  @override
  State<PigTypesScreen> createState() => _PigTypesScreenState();
}

class _PigTypesScreenState extends State<PigTypesScreen> {
  final _pigTypeRepo = sl<IPigTypeRepository>();
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐷 Quản lý loại heo'),
        actions: [
          IconButton(
            tooltip: 'Thêm loại heo',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPigTypeDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<PigTypeEntity>>(
        stream: _pigTypeRepo.watchPigTypes(),
        builder: (context, snapshot) {
          final pigTypes = snapshot.data ?? [];
          if (pigTypes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có loại heo nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPigTypeDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm loại heo'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pigTypes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pigType = pigTypes[index];
              return _buildPigTypeCard(pigType);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPigTypeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPigTypeCard(PigTypeEntity pigType) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            pigType.name.isNotEmpty ? pigType.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ),
        title: Text(
          pigType.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: pigType.description != null && pigType.description!.isNotEmpty
            ? Text(
                pigType.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Sửa',
              onPressed: () => _showEditPigTypeDialog(pigType),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Xóa',
              onPressed: () => _confirmDeletePigType(pigType),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPigTypeDialog() async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('➕ Thêm loại heo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên loại heo',
                border: OutlineInputBorder(),
                hintText: 'VD: Heo lai, Heo rừng...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtl,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('THÊM'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    final entity = PigTypeEntity(
      id: _uuid.v4(),
      name: name,
      description: descCtl.text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _pigTypeRepo.addPigType(entity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm loại heo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi thêm: $e')),
        );
      }
    }
  }

  Future<void> _showEditPigTypeDialog(PigTypeEntity pigType) async {
    final nameCtl = TextEditingController(text: pigType.name);
    final descCtl = TextEditingController(text: pigType.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✏️ Sửa loại heo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên loại heo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtl,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LƯU'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    final updated = pigType.copyWith(
      name: name,
      description: descCtl.text.trim(),
    );
    try {
      await _pigTypeRepo.updatePigType(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã cập nhật loại heo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeletePigType(PigTypeEntity pigType) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗑️ Xóa loại heo'),
        content: Text('Bạn có chắc muốn xóa loại heo "${pigType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _pigTypeRepo.deletePigType(pigType.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa loại heo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi xóa: $e')),
        );
      }
    }
  }
}
