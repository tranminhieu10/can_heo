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
  final _repo = sl<IPigTypeRepository>();
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loại heo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<PigTypeEntity>>(
        stream: _repo.watchPigTypes(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có loại heo nào. Thêm mới để sử dụng.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: item.description != null ? Text(item.description!) : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(item)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item)),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm loại heo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Tên')),
          TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('THÊM')),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    final entity = PigTypeEntity(id: _uuid.v4(), name: name, description: descCtl.text.trim(), createdAt: DateTime.now());
    try {
      await _repo.addPigType(entity);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm loại heo')));
      // clear controllers to avoid leftover text if dialog reopened
      nameCtl.clear();
      descCtl.clear();
      setState(() {});
    } catch (e, st) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi thêm: $e')));
      // rethrow for visibility in debug
      // ignore: avoid_print
      print('Error adding pig type: $e\n$st');
    }
  }

  Future<void> _showEditDialog(PigTypeEntity item) async {
    final nameCtl = TextEditingController(text: item.name);
    final descCtl = TextEditingController(text: item.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa loại heo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Tên')),
          TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('LƯU')),
        ],
      ),
    );
    if (result != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    final updated = item.copyWith(name: name, description: descCtl.text.trim());
    try {
      await _repo.updatePigType(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi')));
      setState(() {});
    } catch (e, st) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      // ignore: avoid_print
      print('Error updating pig type: $e\n$st');
    }
  }

  Future<void> _confirmDelete(PigTypeEntity item) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Xóa loại heo'),
      content: Text('Bạn có chắc muốn xóa "${item.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('HỦY')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('XÓA'))],
    ));
    if (ok == true) {
      try {
        await _repo.deletePigType(item.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
        setState(() {});
      } catch (e, st) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
        // ignore: avoid_print
        print('Error deleting pig type: $e\n$st');
      }
    }
  }
}
