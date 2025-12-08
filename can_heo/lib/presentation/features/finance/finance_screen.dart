import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/partner.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../injection_container.dart';
import '../partners/bloc/partner_bloc.dart';
import '../partners/bloc/partner_event.dart';
import '../partners/bloc/partner_state.dart';
import 'bloc/finance_bloc.dart';
import 'bloc/finance_event.dart';
import 'bloc/finance_state.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FinanceBloc>()..add(LoadTransactions())),
        BlocProvider(create: (_) => sl<PartnerBloc>()..add(const LoadPartners(false))),
      ],
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatelessWidget {
  const _FinanceView();

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("TÀI CHÍNH & CÔNG NỢ"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'finance_screen_fab',
        onPressed: () => _showTransactionDialog(context),
        label: const Text("LẬP PHIẾU"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Dashboard Thống kê
          BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) {
              final balance = state.totalIncome - state.totalExpense;
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal[800],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("TỔNG THU", state.totalIncome, Colors.greenAccent, currencyFormat),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildStatItem("TỔNG CHI", state.totalExpense, Colors.redAccent, currencyFormat),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildStatItem("DÒNG TIỀN", balance, Colors.white, currencyFormat),
                  ],
                ),
              );
            },
          ),

          // Danh sách
          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, state) {
                if (state.status == FinanceStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.transactions.isEmpty) {
                  return const Center(child: Text("Chưa có giao dịch nào"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.transactions.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trans = state.transactions[index];
                    final isIncome = trans.type == 0; 
                    final isBank = trans.paymentMethod == 1; // 1 = Bank

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () => _showDetailDialog(context, trans),
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
                            child: Icon(
                              // Icon hiển thị loại tiền (Bank vs Cash)
                              isBank ? Icons.qr_code : Icons.attach_money,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            trans.partnerName ?? "Khách lẻ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${DateFormat('dd/MM HH:mm').format(trans.date)} - ${isBank ? 'Chuyển khoản' : 'Tiền mặt'}",
                          ),
                          trailing: Text(
                            "${isIncome ? '+' : '-'}${currencyFormat.format(trans.amount)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncome ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
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

  Widget _buildStatItem(String label, double value, Color color, NumberFormat format) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(format.format(value), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  void _showTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<FinanceBloc>()),
          BlocProvider(create: (_) => sl<PartnerBloc>()..add(const LoadPartners(false))),
        ],
        child: const _AddTransactionDialog(),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, TransactionEntity trans) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isBank = trans.paymentMethod == 1;
    final isIncome = trans.type == 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIncome ? "CHI TIẾT PHIẾU THU" : "CHI TIẾT PHIẾU CHI"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Đối tác:", trans.partnerName ?? "Khách lẻ"),
            _detailRow("Số tiền:", currencyFormat.format(trans.amount), isBold: true),
            _detailRow("Hình thức:", isBank ? "Chuyển khoản / QR" : "Tiền mặt"),
            _detailRow("Thời gian:", DateFormat('dd/MM/yyyy HH:mm').format(trans.date)),
            _detailRow("Ghi chú:", trans.note ?? "Không có"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  const _AddTransactionDialog();

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  int _type = 0; // 0: Thu, 1: Chi
  int _paymentMethod = 0; // 0: Tiền mặt, 1: Chuyển khoản
  PartnerEntity? _selectedPartner;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Lập phiếu Thu / Chi"),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Loại phiếu
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("THU TIỀN")),
                      selected: _type == 0,
                      onSelected: (val) {
                        if (val) {
                          setState(() { _type = 0; _selectedPartner = null; });
                          context.read<PartnerBloc>().add(const LoadPartners(false));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("CHI TIỀN")),
                      selected: _type == 1,
                      onSelected: (val) {
                        if (val) {
                          setState(() { _type = 1; _selectedPartner = null; });
                          context.read<PartnerBloc>().add(const LoadPartners(true));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Hình thức thanh toán (Mới)
              const Text("Hình thức thanh toán:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text("Tiền mặt"),
                      value: 0,
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text("Chuyển khoản"),
                      value: 1,
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              // 3. Chọn đối tác
              BlocBuilder<PartnerBloc, PartnerState>(
                builder: (context, state) {
                   final safeValue = (state.partners.contains(_selectedPartner)) ? _selectedPartner : null;
                  return DropdownButtonFormField<PartnerEntity>(
                    value: safeValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _type == 0 ? "Khách hàng" : "Nhà cung cấp",
                      border: const OutlineInputBorder(),
                    ),
                    items: state.partners.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) => setState(() => _selectedPartner = val),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4. Số tiền
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: "Số tiền (VNĐ)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              // 5. Ghi chú
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Ghi chú", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (_selectedPartner == null || amount <= 0) return;

            final transaction = TransactionEntity(
              id: const Uuid().v4(),
              partnerId: _selectedPartner!.id,
              partnerName: _selectedPartner!.name,
              amount: amount,
              type: _type,
              paymentMethod: _paymentMethod, // Lưu phương thức
              date: DateTime.now(),
              note: _noteController.text.isEmpty 
                  ? (_type == 0 ? "Thu tiền hàng" : "Thanh toán tiền hàng") 
                  : _noteController.text,
            );

            context.read<FinanceBloc>().add(CreateTransaction(transaction));
            Navigator.pop(context);
          },
          child: const Text("Lưu phiếu"),
        ),
      ],
    );
  }
}