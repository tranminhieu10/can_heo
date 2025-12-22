import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/partner.dart';
import '../../../domain/entities/farm.dart';
import '../../../domain/repositories/i_farm_repository.dart';
import '../../../injection_container.dart';
import 'bloc/partner_bloc.dart';
import 'bloc/partner_event.dart';
import 'bloc/partner_state.dart';

/// Màn hình quản lý Công ty (NCC) và Trại
class CompanyFarmScreen extends StatelessWidget {
  const CompanyFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartnerBloc>()..add(const LoadPartners(true)), // Load suppliers
      child: const _CompanyFarmView(),
    );
  }
}

class _CompanyFarmView extends StatefulWidget {
  const _CompanyFarmView();

  @override
  State<_CompanyFarmView> createState() => _CompanyFarmViewState();
}

class _CompanyFarmViewState extends State<_CompanyFarmView> {
  PartnerEntity? _selectedCompany;
  final _farmRepo = sl<IFarmRepository>();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Cột 1: Danh sách Công ty (NCC)
          Expanded(
            flex: 1,
            child: _buildCompanyList(),
          ),
          const VerticalDivider(width: 1),
          // Cột 2: Danh sách Trại của Công ty đã chọn
          Expanded(
            flex: 1,
            child: _buildFarmList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CÔNG TY (NCC)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () => _showAddCompanyDialog(),
                tooltip: 'Thêm công ty',
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: BlocBuilder<PartnerBloc, PartnerState>(
            builder: (context, state) {
              if (state.status == PartnerStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final companies = state.partners;
              if (companies.isEmpty) {
                return const Center(
                  child: Text('Chưa có công ty nào', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final isSelected = _selectedCompany?.id == company.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: isSelected ? Colors.blue[100] : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(Icons.business, color: Colors.orange[800], size: 20),
                      ),
                      title: Text(
                        company.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Nợ: ${_currencyFormat.format(company.currentDebt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: company.currentDebt >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditCompanyDialog(company);
                          } else if (value == 'delete') {
                            _confirmDeleteCompany(company);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                          const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCompany = company;
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFarmList() {
    if (_selectedCompany == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chọn một công ty để xem danh sách trại', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green[50],
          child: Row(
            children: [
              const Icon(Icons.agriculture, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TRẠI CỦA ${_selectedCompany!.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showAddFarmDialog(),
                tooltip: 'Thêm trại',
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: StreamBuilder<List<FarmEntity>>(
            stream: _farmRepo.watchFarmsByPartner(_selectedCompany!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final farms = snapshot.data ?? [];
              if (farms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.agriculture, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Công ty này chưa có trại nào', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddFarmDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm trại'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: farms.length,
                itemBuilder: (context, index) {
                  final farm = farms[index];
                  
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.agriculture, color: Colors.green[800], size: 20),
                      ),
                      title: Text(farm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (farm.address != null && farm.address!.isNotEmpty)
                            Text(farm.address!, style: const TextStyle(fontSize: 12)),
                          if (farm.phone != null && farm.phone!.isNotEmpty)
                            Text('SĐT: ${farm.phone}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditFarmDialog(farm);
                          } else if (value == 'delete') {
                            _confirmDeleteFarm(farm);
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
    );
  }

  void _showAddCompanyDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Công Ty Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên công ty *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final company = PartnerEntity(
                id: const Uuid().v4(),
                name: nameController.text,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
                isSupplier: true,
                currentDebt: 0,
              );
              context.read<PartnerBloc>().add(AddPartner(company));
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(PartnerEntity company) {
    final nameController = TextEditingController(text: company.name);
    final phoneController = TextEditingController(text: company.phone ?? '');
    final addressController = TextEditingController(text: company.address ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa Công Ty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên công ty *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final updated = company.copyWith(
                name: nameController.text,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
              );
              context.read<PartnerBloc>().add(UpdatePartnerInfo(updated));
              if (_selectedCompany?.id == company.id) {
                setState(() => _selectedCompany = updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompany(PartnerEntity company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Công Ty'),
        content: Text('Bạn có chắc muốn xóa ${company.name}?\nCác trại thuộc công ty này cũng sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              context.read<PartnerBloc>().add(DeletePartner(company.id));
              if (_selectedCompany?.id == company.id) {
                setState(() => _selectedCompany = null);
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAddFarmDialog() {
    if (_selectedCompany == null) return;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm Trại cho ${_selectedCompany!.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên trại *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
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
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final farm = FarmEntity(
                id: const Uuid().v4(),
                name: nameController.text,
                partnerId: _selectedCompany!.id,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
                note: noteController.text.isEmpty ? null : noteController.text,
                createdAt: DateTime.now(),
              );
              await _farmRepo.addFarm(farm);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditFarmDialog(FarmEntity farm) {
    final nameController = TextEditingController(text: farm.name);
    final phoneController = TextEditingController(text: farm.phone ?? '');
    final addressController = TextEditingController(text: farm.address ?? '');
    final noteController = TextEditingController(text: farm.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa Trại'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên trại *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
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
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final updated = farm.copyWith(
                name: nameController.text,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              await _farmRepo.updateFarm(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFarm(FarmEntity farm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Trại'),
        content: Text('Bạn có chắc muốn xóa trại ${farm.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              await _farmRepo.deleteFarm(farm.id);
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
