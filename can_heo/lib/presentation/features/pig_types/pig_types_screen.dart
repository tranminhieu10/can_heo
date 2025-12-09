import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/pig_type.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/repositories/i_pigtype_repository.dart';
import '../../../domain/repositories/i_invoice_repository.dart';
import '../../../injection_container.dart';

class PigTypesScreen extends StatefulWidget {
  const PigTypesScreen({super.key});

  @override
  State<PigTypesScreen> createState() => _PigTypesScreenState();
}

class _PigTypesScreenState extends State<PigTypesScreen> {
  final _pigTypeRepo = sl<IPigTypeRepository>();
  final _invoiceRepo = sl<IInvoiceRepository>();
  final _numberFormat = NumberFormat('#,##0', 'en_US');
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Thống kê số lượng heo'),
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
            return const Center(
              child:
                  Text('Chưa có loại heo nào. Vui lòng thêm loại heo trước.'),
            );
          }

          return StreamBuilder<List<InvoiceEntity>>(
            stream: _invoiceRepo.watchInvoices(type: 0),
            builder: (context, importSnapshot) {
              final importInvoices = importSnapshot.data ?? [];

              return StreamBuilder<List<InvoiceEntity>>(
                stream: _invoiceRepo.watchInvoices(type: 2),
                builder: (context, exportSnapshot) {
                  final exportInvoices = exportSnapshot.data ?? [];
                  final allInvoices = [...importInvoices, ...exportInvoices];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header thống kê tổng
                        _buildSummaryCard(pigTypes, allInvoices),
                        const SizedBox(height: 20),

                        // Danh sách chi tiết theo loại heo
                        const Text(
                          'Chi tiết theo loại heo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pigTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pigType = pigTypes[index];
                            return _buildPigTypeCard(pigType, allInvoices);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    List<PigTypeEntity> pigTypes,
    List<InvoiceEntity> allInvoices,
  ) {
    int totalImportedFromSupplier = 0;
    int totalReturnedFromMarket = 0;
    int totalExported = 0;

    for (final inv in allInvoices) {
      if (inv.type == 0) {
        // Nhập kho
        totalImportedFromSupplier += inv.totalQuantity;
      } else if (inv.type == 2) {
        // Xuất chợ
        totalExported += inv.totalQuantity;
      }
      // Hoàn hàng từ chợ sẽ được tính trong type = 0 với description khác
    }

    final totalInStock = totalImportedFromSupplier - totalExported;

    return Card(
      elevation: 4,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'TỔNG THỐNG KÊ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  '🏭 Nhập từ Trại',
                  totalImportedFromSupplier,
                  Colors.blue,
                ),
                _buildStatItem(
                  '↩️ Hoàn từ Chợ',
                  totalReturnedFromMarket,
                  Colors.green,
                ),
                _buildStatItem(
                  '📤 Đã Bán',
                  totalExported,
                  Colors.red,
                ),
                _buildStatItem(
                  '📦 Tồn Kho',
                  totalInStock,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int quantity, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_numberFormat.format(quantity)} con',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPigTypeCard(
    PigTypeEntity pigType,
    List<InvoiceEntity> allInvoices,
  ) {
    int imported = 0;
    int returned = 0;
    int exported = 0;

    for (final inv in allInvoices) {
      final pigTypeInInv =
          inv.details.isNotEmpty ? inv.details.first.pigType ?? '' : '';

      if (pigTypeInInv != pigType.name) continue;

      if (inv.type == 0) {
        // Nhập kho
        imported += inv.totalQuantity;
      } else if (inv.type == 2) {
        // Xuất chợ
        exported += inv.totalQuantity;
      }
    }

    final inStock = imported - exported;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pigType.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (pigType.description != null &&
                          pigType.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            pigType.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_numberFormat.format(inStock)} con tồn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: inStock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Sửa',
                          onPressed: () =>
                              _showEditPigTypeDialog(pigType),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          tooltip: 'Xóa',
                          onPressed: () =>
                              _confirmDeletePigType(pigType),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('🏭 Nhập', imported, Colors.blue),
                _buildStatColumn('↩️ Hoàn', returned, Colors.green),
                _buildStatColumn('📤 Bán', exported, Colors.red),
                _buildStatColumn('📦 Tồn', inStock, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int quantity, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          _numberFormat.format(quantity),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'con',
          style: TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
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
          TextButton(
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
          TextButton(
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
          TextButton(
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
