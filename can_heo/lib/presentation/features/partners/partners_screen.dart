import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/partner.dart';
import '../../../../injection_container.dart';
import 'bloc/partner_bloc.dart';
import 'bloc/partner_event.dart';
import 'bloc/partner_state.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartnerBloc>()..add(const LoadPartners(false)),
      child: const _PartnersView(),
    );
  }
}

class _PartnersView extends StatelessWidget {
  const _PartnersView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("QUẢN LÝ ĐỐI TÁC"),
          elevation: 0,
          backgroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            onTap: (index) {
              context.read<PartnerBloc>().add(LoadPartners(index == 1));
            },
            tabs: const [
              Tab(icon: Icon(Icons.people), text: "KHÁCH HÀNG (LÁI)"),
              Tab(icon: Icon(Icons.store), text: "TRẠI HEO (NCC)"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'partners_screen_fab',
          onPressed: () => _showAddPartnerDialog(context),
          label: const Text("THÊM MỚI"),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
        body: const _PartnerList(),
      ),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    final isSupplier = context.read<PartnerBloc>().state.isSupplierFilter;
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PartnerBloc>(),
        child: _AddPartnerDialog(isSupplier: isSupplier),
      ),
    );
  }
}

class _PartnerList extends StatelessWidget {
  const _PartnerList();

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return BlocBuilder<PartnerBloc, PartnerState>(
      builder: (context, state) {
        if (state.status == PartnerStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.partners.isEmpty) {
          return Center(
            child: Text(
              state.isSupplierFilter ? "Chưa có Trại heo nào" : "Chưa có Khách hàng nào",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.partners.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final partner = state.partners[index];
            final isPositive = partner.currentDebt >= 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: state.isSupplierFilter ? Colors.orange[100] : Colors.blue[100],
                  child: Icon(
                    state.isSupplierFilter ? Icons.store : Icons.person,
                    color: state.isSupplierFilter ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
                title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(partner.phone ?? "Không có SĐT"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Dư nợ:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          currencyFormat.format(partner.currentDebt),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Nút Xóa
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, partner),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PartnerEntity partner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa đối tác"),
        content: Text("Bạn có chắc muốn xóa ${partner.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          FilledButton(
            onPressed: () {
              context.read<PartnerBloc>().add(DeletePartner(partner.id));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          )
        ],
      ),
    );
  }
}

class _AddPartnerDialog extends StatefulWidget {
  final bool isSupplier;
  const _AddPartnerDialog({required this.isSupplier});

  @override
  State<_AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<_AddPartnerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSupplier ? "Thêm Trại Heo Mới" : "Thêm Khách Hàng Mới"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Tên đối tác *", border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? "Cần nhập tên" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Địa chỉ", border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newPartner = PartnerEntity(
                id: const Uuid().v4(),
                name: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                isSupplier: widget.isSupplier,
                currentDebt: 0,
              );
              context.read<PartnerBloc>().add(AddPartner(newPartner));
              Navigator.pop(context);
            }
          },
          child: const Text("Thêm"),
        ),
      ],
    );
  }
}