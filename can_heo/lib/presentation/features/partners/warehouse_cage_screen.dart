import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/cage.dart';
import '../../../domain/repositories/i_cage_repository.dart';
import '../../../injection_container.dart';

/// Màn hình quản lý Chuồng Kho (không thuộc trại nào)
class WarehouseCageScreen extends StatelessWidget {
  const WarehouseCageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cageRepo = sl<ICageRepository>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CHUỒNG KHO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _showAddCageDialog(context, cageRepo),
                  tooltip: 'Thêm chuồng kho',
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<List<CageEntity>>(
              stream: cageRepo.watchAllCages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cages = snapshot.data ?? [];
                if (cages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Chưa có chuồng kho nào', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddCageDialog(context, cageRepo),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm chuồng kho'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: cages.length,
                  itemBuilder: (context, index) {
                    final cage = cages[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.home, color: Colors.blue[800], size: 20),
                        ),
                        title: Text(cage.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cage.capacity != null)
                              Text('Sức chứa: ${cage.capacity} con', style: const TextStyle(fontSize: 12)),
                            if (cage.note != null && cage.note!.isNotEmpty)
                              Text(cage.note!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditCageDialog(context, cageRepo, cage);
                            } else if (value == 'delete') {
                              _confirmDeleteCage(context, cageRepo, cage);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static void _showAddCageDialog(BuildContext context, ICageRepository cageRepo) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Chuồng Kho'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên chuồng *',
                border: OutlineInputBorder(),
                hintText: 'VD: Chuồng A1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(
                labelText: 'Sức chứa (số con)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final cage = CageEntity(
                id: const Uuid().v4(),
                name: nameController.text,
                capacity: capacityController.text.isEmpty ? null : int.tryParse(capacityController.text),
                note: noteController.text.isEmpty ? null : noteController.text,
                createdAt: DateTime.now(),
              );
              await cageRepo.addCage(cage);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  static void _showEditCageDialog(BuildContext context, ICageRepository cageRepo, CageEntity cage) {
    final nameController = TextEditingController(text: cage.name);
    final capacityController = TextEditingController(text: cage.capacity?.toString() ?? '');
    final noteController = TextEditingController(text: cage.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa Chuồng Kho'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên chuồng *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Sức chứa (số con)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final updated = cage.copyWith(
                name: nameController.text,
                capacity: capacityController.text.isEmpty ? null : int.tryParse(capacityController.text),
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              await cageRepo.updateCage(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  static void _confirmDeleteCage(BuildContext context, ICageRepository cageRepo, CageEntity cage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Chuồng'),
        content: Text('Bạn có chắc muốn xóa chuồng ${cage.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              await cageRepo.deleteCage(cage.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
