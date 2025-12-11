import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../data/local/database.dart';
import '../../../../domain/entities/partner.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';

/// Debt section widget for managing partner debts
class DebtSection extends StatelessWidget {
  final PartnerEntity? selectedPartner;
  final InvoiceEntity? lastSavedInvoice;
  final TextEditingController paymentAmountController;
  final TextEditingController invoicePaymentAmountController;
  final int selectedPaymentMethod;
  final int selectedDebtPaymentMethod;
  final void Function(int) onPaymentMethodChanged;
  final void Function(int) onDebtPaymentMethodChanged;
  final VoidCallback onConfirmPayment;
  final NumberFormat currencyFormat;
  final NumberFormat numberFormat;
  final AppDatabase db;

  const DebtSection({
    super.key,
    required this.selectedPartner,
    required this.lastSavedInvoice,
    required this.paymentAmountController,
    required this.invoicePaymentAmountController,
    required this.selectedPaymentMethod,
    required this.selectedDebtPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.onDebtPaymentMethodChanged,
    required this.onConfirmPayment,
    required this.currencyFormat,
    required this.numberFormat,
    required this.db,
  });

  Future<Map<String, dynamic>> _calculatePartnerDebt(String partnerId) async {
    final invoiceRepo = sl<IInvoiceRepository>();
    final invoices = await invoiceRepo.watchInvoices(type: 2).first;
    final partnerInvoices =
        invoices.where((inv) => inv.partnerId == partnerId).toList();

    double totalDebt = 0;
    for (final inv in partnerInvoices) {
      totalDebt += inv.finalAmount;
    }

    final transactions =
        await db.transactionsDao.watchTransactionsByPartner(partnerId).first;
    double totalPaid = 0;
    for (final tx in transactions) {
      if (tx.type == 0) {
        totalPaid += tx.amount;
      }
    }

    return {
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'remaining': (totalDebt - totalPaid).clamp(0, double.infinity),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasPartner = selectedPartner != null;
    final partnerId = selectedPartner?.id;
    final partnerName = selectedPartner?.name ?? 'Chưa chọn khách hàng';

    return Card(
      elevation: 3,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'CÔNG NỢ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Text(
                  'Khách: $partnerName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: hasPartner ? Colors.black : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (hasPartner && partnerId != null) ...[
                  SizedBox(
                    height: 32,
                    child: FilledButton.icon(
                      onPressed: onConfirmPayment,
                      icon: const Icon(Icons.check, size: 14),
                      label:
                          const Text('Xác nhận', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showPartnerDebtDetail(context, partnerId),
                    icon: const Icon(Icons.visibility, size: 16),
                    label:
                        const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const Divider(height: 16),

            // Content - Empty placeholder or actual data
            if (!hasPartner)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng chọn khách hàng để xem công nợ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _buildPartnerDebtContent(context, partnerId!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerDebtContent(BuildContext context, String partnerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculatePartnerDebt(partnerId),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final totalDebt = debtInfo['totalDebt'] ?? 0.0;
        final totalPaid = debtInfo['totalPaid'] ?? 0.0;
        final remaining = debtInfo['remaining'] ?? 0.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Transaction histories (thanh toán + trả nợ)
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: _buildTransactionHistory(partnerId,
                          type: 0, title: 'Lịch sử thanh toán')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTransactionHistory(partnerId,
                          type: 1, title: 'Lịch sử trả nợ')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: Payment forms + Summary boxes
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment forms
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hình thức thanh toán (phiếu mới)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Tiền mặt',
                                    style: TextStyle(fontSize: 10)),
                                selected: selectedPaymentMethod == 0,
                                onSelected: (selected) {
                                  if (selected) onPaymentMethodChanged(0);
                                },
                                selectedColor: Colors.green[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Chuyển khoản',
                                    style: TextStyle(fontSize: 10)),
                                selected: selectedPaymentMethod == 1,
                                onSelected: (selected) {
                                  if (selected) onPaymentMethodChanged(1);
                                },
                                selectedColor: Colors.blue[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Nợ',
                                    style: TextStyle(fontSize: 10)),
                                selected: selectedPaymentMethod == 2,
                                onSelected: (selected) {
                                  if (selected) onPaymentMethodChanged(2);
                                },
                                selectedColor: Colors.red[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: invoicePaymentAmountController,
                              keyboardType: TextInputType.number,
                              enabled: selectedPaymentMethod != 2,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixText: 'đ',
                                suffixStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                filled: selectedPaymentMethod == 2,
                                fillColor: Colors.grey[200],
                                hintText: 'Số tiền TT phiếu',
                                hintStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text('Hình thức trả nợ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Tiền mặt',
                                    style: TextStyle(fontSize: 10)),
                                selected: selectedDebtPaymentMethod == 0,
                                onSelected: (selected) {
                                  if (selected) onDebtPaymentMethodChanged(0);
                                },
                                selectedColor: Colors.green[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              ChoiceChip(
                                label: const Text('Chuyển khoản',
                                    style: TextStyle(fontSize: 10)),
                                selected: selectedDebtPaymentMethod == 1,
                                onSelected: (selected) {
                                  if (selected) onDebtPaymentMethodChanged(1);
                                },
                                selectedColor: Colors.blue[200],
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: paymentAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixText: 'đ',
                                suffixStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                hintText: 'Số tiền trả nợ',
                                hintStyle: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Summary boxes
                  SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDebtSummaryBox('Tổng nợ', totalDebt, Colors.orange),
                        const SizedBox(height: 6),
                        _buildDebtSummaryBox('Đã trả', totalPaid, Colors.green),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                remaining > 0 ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: remaining > 0 ? Colors.red : Colors.green),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'CÒN NỢ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(remaining),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: remaining > 0
                                      ? Colors.red[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebtSummaryBox(String label, double value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(String partnerId,
      {int type = 0, String title = 'Lịch sử thanh toán'}) {
    return StreamBuilder<List<Transaction>>(
      stream: db.transactionsDao.watchTransactionsByPartner(partnerId),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? [];
        final transactions =
            allTransactions.where((tx) => tx.type == type).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          type == 0 ? 'Chưa có thanh toán' : 'Chưa có trả nợ',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                columnSpacing: 8,
                                dataRowMinHeight: 32,
                                dataRowMaxHeight: 36,
                                headingRowHeight: 34,
                                columns: const [
                                  DataColumn(
                                      label: Text('STT',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Hình thức',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Số tiền',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Ngày',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: List.generate(transactions.take(10).length,
                                    (idx) {
                                  final tx = transactions[idx];
                                  final paymentMethod = tx.paymentMethod == 0
                                      ? 'Tiền mặt'
                                      : 'Chuyển khoản';
                                  return DataRow(cells: [
                                    DataCell(Text('${idx + 1}',
                                        style: const TextStyle(fontSize: 10))),
                                    DataCell(Text(paymentMethod,
                                        style: const TextStyle(fontSize: 10))),
                                    DataCell(Text(
                                      currencyFormat.format(tx.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: type == 0 ? Colors.green : Colors.blue,
                                      ),
                                    )),
                                    DataCell(Text(
                                      DateFormat('dd/MM').format(tx.transactionDate),
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.grey),
                                    )),
                                  ]);
                                }),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPartnerDebtDetail(BuildContext context, String partnerId) async {
    final invoiceRepo = sl<IInvoiceRepository>();
    final debtInfo = await _calculatePartnerDebt(partnerId);
    final invoices = await invoiceRepo.watchInvoices(type: 2).first;
    final partnerInvoices =
        invoices.where((inv) => inv.partnerId == partnerId).toList();
    final transactions =
        await db.transactionsDao.watchTransactionsByPartner(partnerId).first;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Chi tiết công nợ - ${lastSavedInvoice?.partnerName ?? selectedPartner?.name ?? ""}'),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('TỔNG NỢ',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                currencyFormat.format(debtInfo['totalDebt']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('ĐÃ TRẢ',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                currencyFormat.format(debtInfo['totalPaid']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('CÒN LẠI',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                currencyFormat.format(debtInfo['remaining']),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Invoices list
                const Text('Danh sách phiếu:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DataTable(
                  columnSpacing: 12,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('TL (kg)')),
                    DataColumn(label: Text('Đơn giá')),
                    DataColumn(label: Text('Thành tiền')),
                  ],
                  rows: partnerInvoices
                      .map((inv) => DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yy')
                                .format(inv.createdDate))),
                            DataCell(Text(numberFormat.format(inv.totalWeight))),
                            DataCell(
                                Text(currencyFormat.format(inv.pricePerKg))),
                            DataCell(Text(
                                currencyFormat.format(inv.finalAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                          ]))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Payments list
                const Text('Lịch sử thanh toán:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                transactions.isEmpty
                    ? const Text('Chưa có thanh toán',
                        style: TextStyle(color: Colors.grey))
                    : DataTable(
                        columnSpacing: 12,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 36,
                        columns: const [
                          DataColumn(label: Text('Ngày')),
                          DataColumn(label: Text('Hình thức')),
                          DataColumn(label: Text('Số tiền')),
                          DataColumn(label: Text('Ghi chú')),
                        ],
                        rows: transactions
                            .map((tx) => DataRow(cells: [
                                  DataCell(Text(DateFormat('dd/MM/yy HH:mm')
                                      .format(tx.transactionDate))),
                                  DataCell(Text(tx.paymentMethod == 0
                                      ? 'Tiền mặt'
                                      : 'Chuyển khoản')),
                                  DataCell(Text(
                                    currencyFormat.format(tx.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  )),
                                  DataCell(Text(tx.note ?? '-')),
                                ]))
                            .toList(),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
