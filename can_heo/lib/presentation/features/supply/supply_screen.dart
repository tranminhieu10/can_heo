import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/supply.dart';
import '../../../domain/repositories/i_supply_repository.dart';
import '../../../injection_container.dart';

/// Màn hình Quản lý Vật tư
class SupplyScreen extends StatefulWidget {
  const SupplyScreen({super.key});

  @override
  State<SupplyScreen> createState() => _SupplyScreenState();
}

class _SupplyScreenState extends State<SupplyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supplyRepo = sl<ISupplyRepository>();
  final _numberFormat = NumberFormat('#,###');
  final _uuid = const Uuid();

  // Danh sách loại vật tư
  final List<String> _categories = [
    'Thức ăn',
    'Thuốc',
    'Vaccine',
    'Dụng cụ',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Vật tư'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Danh sách'),
            Tab(icon: Icon(Icons.add_box), text: 'Nhập/Xuất'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupplyListTab(),
          _buildImportExportTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm vật tư'),
        backgroundColor: Colors.teal.shade600,
      ),
    );
  }

  // ==================== TAB 1: DANH SÁCH VẬT TƯ ====================
  Widget _buildSupplyListTab() {
    return StreamBuilder<List<SupplyEntity>>(
      stream: _supplyRepo.watchSupplies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final supplies = snapshot.data!;
        if (supplies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có vật tư nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để thêm vật tư mới',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Group theo category
        final grouped = <String, List<SupplyEntity>>{};
        for (final supply in supplies) {
          final cat = supply.category ?? 'Khác';
          grouped.putIfAbsent(cat, () => []).add(supply);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thống kê tổng quan
            _buildSummaryCard(supplies),
            const SizedBox(height: 16),

            // Danh sách theo nhóm
            ...grouped.entries.map((entry) => _buildCategorySection(entry.key, entry.value)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(List<SupplyEntity> supplies) {
    final lowStock = supplies.where((s) => s.minQuantity != null && s.quantity < s.minQuantity!).length;
    final totalValue = supplies.fold<double>(0, (sum, s) => sum + (s.quantity * (s.pricePerUnit ?? 0)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Tổng số', '${supplies.length}', 'loại', Icons.category),
          ),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(
            child: _buildStatItem('Sắp hết', '$lowStock', 'loại', Icons.warning_amber, 
                color: lowStock > 0 ? Colors.orange : Colors.white),
          ),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(
            child: _buildStatItem('Tổng giá trị', _numberFormat.format(totalValue), 'đ', Icons.attach_money),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          '$label ($unit)',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<SupplyEntity> supplies) {
    final categoryIcons = {
      'Thức ăn': Icons.restaurant,
      'Thuốc': Icons.medication,
      'Vaccine': Icons.vaccines,
      'Dụng cụ': Icons.build,
      'Khác': Icons.more_horiz,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(categoryIcons[category] ?? Icons.category, 
                  size: 20, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${supplies.length}',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),
        ),
        ...supplies.map((s) => _buildSupplyCard(s)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSupplyCard(SupplyEntity supply) {
    final isLowStock = supply.minQuantity != null && supply.quantity < supply.minQuantity!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSupplyDetailDialog(supply),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.orange.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLowStock ? Icons.warning_amber : Icons.inventory_2,
                  color: isLowStock ? Colors.orange : Colors.teal,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supply.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (supply.code != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              supply.code!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Tồn: ${_numberFormat.format(supply.quantity)} ${supply.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isLowStock ? Colors.orange : Colors.grey.shade700,
                            fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (supply.minQuantity != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(min: ${_numberFormat.format(supply.minQuantity)})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                    if (supply.pricePerUnit != null)
                      Text(
                        'Đơn giá: ${_numberFormat.format(supply.pricePerUnit)} đ/${supply.unit}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditSupplyDialog(supply);
                      break;
                    case 'delete':
                      _confirmDeleteSupply(supply);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 2: NHẬP/XUẤT ====================
  Widget _buildImportExportTab() {
    return StreamBuilder<List<SupplyEntity>>(
      stream: _supplyRepo.watchSupplies(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final supplies = snapshot.data!;
        if (supplies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Chưa có vật tư nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddSupplyDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm vật tư'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Nhập vật tư
              Expanded(
                child: _buildImportExportCard(
                  title: 'Nhập vật tư',
                  icon: Icons.add_box,
                  color: Colors.green,
                  supplies: supplies,
                  isImport: true,
                ),
              ),
              const SizedBox(width: 16),
              // Xuất vật tư
              Expanded(
                child: _buildImportExportCard(
                  title: 'Xuất vật tư',
                  icon: Icons.outbox,
                  color: Colors.orange,
                  supplies: supplies,
                  isImport: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportExportCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<SupplyEntity> supplies,
    required bool isImport,
  }) {
    SupplyEntity? selectedSupply;
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final noteController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chọn vật tư
                DropdownButtonFormField<SupplyEntity>(
                  initialValue: selectedSupply,
                  decoration: const InputDecoration(
                    labelText: 'Chọn vật tư',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  items: supplies.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s.name} (${_numberFormat.format(s.quantity)} ${s.unit})'),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSupply = v;
                      if (v != null && v.pricePerUnit != null) {
                        priceController.text = v.pricePerUnit!.toStringAsFixed(0);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Số lượng
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                    suffixText: selectedSupply?.unit ?? '',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
                const SizedBox(height: 16),

                // Đơn giá (chỉ hiện khi nhập)
                if (isImport) ...[
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá (đ)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                ],

                // Ghi chú
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                
                const Spacer(),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedSupply == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn vật tư'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final qty = double.tryParse(quantityController.text) ?? 0;
                      if (qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập số lượng'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      // Kiểm tra xuất kho
                      if (!isImport && qty > selectedSupply!.quantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Số lượng tồn không đủ (còn ${_numberFormat.format(selectedSupply!.quantity)} ${selectedSupply!.unit})'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        if (isImport) {
                          final price = double.tryParse(priceController.text);
                          await _supplyRepo.importSupply(
                            selectedSupply!.id,
                            qty,
                            pricePerUnit: price,
                            note: noteController.text.isNotEmpty ? noteController.text : null,
                          );
                        } else {
                          await _supplyRepo.exportSupply(
                            selectedSupply!.id,
                            qty,
                            note: noteController.text.isNotEmpty ? noteController.text : null,
                          );
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Đã ${isImport ? "nhập" : "xuất"} $qty ${selectedSupply!.unit} ${selectedSupply!.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reset form
                          setState(() {
                            selectedSupply = null;
                            quantityController.clear();
                            priceController.clear();
                            noteController.clear();
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: Icon(isImport ? Icons.add : Icons.remove),
                    label: Text(isImport ? 'Nhập kho' : 'Xuất kho'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== TAB 3: LỊCH SỬ ====================
  Widget _buildHistoryTab() {
    return StreamBuilder<List<SupplyTransactionEntity>>(
      stream: _supplyRepo.watchTransactionHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Chưa có giao dịch nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        // Group by date
        final grouped = <String, List<SupplyTransactionEntity>>{};
        for (final tx in transactions) {
          final dateKey = DateFormat('dd/MM/yyyy').format(tx.createdDate);
          grouped.putIfAbsent(dateKey, () => []).add(tx);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ...entry.value.map((tx) => _buildTransactionCard(tx)),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTransactionCard(SupplyTransactionEntity tx) {
    final isImport = tx.type == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isImport ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isImport ? Icons.add_box : Icons.outbox,
            color: isImport ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(tx.supplyName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isImport ? "+" : "-"}${_numberFormat.format(tx.quantity)}',
              style: TextStyle(
                color: isImport ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tx.note != null && tx.note!.isNotEmpty)
              Text(tx.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (tx.totalAmount != null)
              Text(
                '${_numberFormat.format(tx.totalAmount)} đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Text(
              DateFormat('HH:mm').format(tx.createdDate),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showAddSupplyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final quantityController = TextEditingController(text: '0');
    final minQuantityController = TextEditingController();
    final priceController = TextEditingController();
    final supplierController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm vật tư mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên vật tư *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã vật tư',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Loại',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => selectedCategory = v ?? _categories.first,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn vị *',
                        border: OutlineInputBorder(),
                        hintText: 'kg, bao, chai...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng ban đầu',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng tối thiểu',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Đơn giá (đ)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Nhà cung cấp',
                  border: OutlineInputBorder(),
                ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || unitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên và đơn vị'), backgroundColor: Colors.orange),
                );
                return;
              }

              final supply = SupplyEntity(
                id: _uuid.v4(),
                name: nameController.text,
                code: codeController.text.isNotEmpty ? codeController.text : null,
                category: selectedCategory,
                unit: unitController.text,
                quantity: double.tryParse(quantityController.text) ?? 0,
                minQuantity: double.tryParse(minQuantityController.text),
                pricePerUnit: double.tryParse(priceController.text),
                supplier: supplierController.text.isNotEmpty ? supplierController.text : null,
                note: noteController.text.isNotEmpty ? noteController.text : null,
                createdDate: DateTime.now(),
              );

              await _supplyRepo.createSupply(supply);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Đã thêm vật tư'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplyDialog(SupplyEntity supply) {
    final nameController = TextEditingController(text: supply.name);
    final codeController = TextEditingController(text: supply.code ?? '');
    final unitController = TextEditingController(text: supply.unit);
    final minQuantityController = TextEditingController(text: supply.minQuantity?.toString() ?? '');
    final priceController = TextEditingController(text: supply.pricePerUnit?.toStringAsFixed(0) ?? '');
    final supplierController = TextEditingController(text: supply.supplier ?? '');
    final noteController = TextEditingController(text: supply.note ?? '');
    String selectedCategory = supply.category ?? _categories.first;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa vật tư'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên vật tư *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Mã vật tư', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Loại', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => selectedCategory = v ?? _categories.first,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Đơn vị *', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minQuantityController,
                      decoration: const InputDecoration(labelText: 'SL tối thiểu', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Đơn giá (đ)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(labelText: 'Nhà cung cấp', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (nameController.text.isEmpty || unitController.text.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên và đơn vị'), backgroundColor: Colors.orange),
                );
                return;
              }

              final updated = supply.copyWith(
                name: nameController.text,
                code: codeController.text.isNotEmpty ? codeController.text : null,
                category: selectedCategory,
                unit: unitController.text,
                minQuantity: double.tryParse(minQuantityController.text),
                pricePerUnit: double.tryParse(priceController.text),
                supplier: supplierController.text.isNotEmpty ? supplierController.text : null,
                note: noteController.text.isNotEmpty ? noteController.text : null,
                updatedDate: DateTime.now(),
              );

              await _supplyRepo.updateSupply(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('✅ Đã cập nhật'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showSupplyDetailDialog(SupplyEntity supply) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supply.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supply.code != null) _detailRow('Mã', supply.code!),
            _detailRow('Loại', supply.category ?? 'Chưa phân loại'),
            _detailRow('Đơn vị', supply.unit),
            _detailRow('Tồn kho', '${_numberFormat.format(supply.quantity)} ${supply.unit}'),
            if (supply.minQuantity != null)
              _detailRow('Tối thiểu', '${_numberFormat.format(supply.minQuantity)} ${supply.unit}'),
            if (supply.pricePerUnit != null)
              _detailRow('Đơn giá', '${_numberFormat.format(supply.pricePerUnit)} đ'),
            if (supply.supplier != null) _detailRow('NCC', supply.supplier!),
            if (supply.note != null) _detailRow('Ghi chú', supply.note!),
            _detailRow('Ngày tạo', DateFormat('dd/MM/yyyy HH:mm').format(supply.createdDate)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _confirmDeleteSupply(SupplyEntity supply) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${supply.name}"?\nLịch sử giao dịch cũng sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _supplyRepo.deleteSupply(supply.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('✅ Đã xóa'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
