import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import 'bloc/invoice_history_bloc.dart';
import 'bloc/invoice_history_event.dart';
import 'bloc/invoice_history_state.dart';

// Import màn hình chi tiết để điều hướng
import 'invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatelessWidget {
  final int invoiceType;

  const InvoiceHistoryScreen({super.key, required this.invoiceType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvoiceHistoryBloc>()..add(LoadInvoices(invoiceType)),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("LỊCH SỬ PHIẾU"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<InvoiceHistoryBloc, InvoiceHistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HistoryStatus.failure) {
            return Center(child: Text("Lỗi: ${state.errorMessage}"));
          }
          if (state.invoices.isEmpty) {
            return const Center(child: Text("Chưa có phiếu nào"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.invoices.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invoice = state.invoices[index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    // Chuyển sang màn hình chi tiết khi bấm vào phiếu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InvoiceDetailScreen(invoiceId: invoice.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.description,
                              color: Colors.blue[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(invoice.partnerName ?? "Khách lẻ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(dateFormat.format(invoice.createdDate),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(invoice.finalAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue)),
                            Text(
                                "${invoice.totalWeight} kg / ${invoice.totalQuantity} con",
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}