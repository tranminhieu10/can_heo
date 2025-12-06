import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import Service (Đã sửa đường dẫn import cho đúng)
import '../../../core/services/printing_service.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../injection_container.dart';
import 'bloc_detail/invoice_detail_cubit.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvoiceDetailCubit>()..loadInvoice(invoiceId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CHI TIẾT PHIẾU")),
      floatingActionButton: BlocBuilder<InvoiceDetailCubit, InvoiceDetailState>(
        builder: (context, state) {
          if (state is InvoiceDetailLoaded) {
            return FloatingActionButton.extended(
              onPressed: () {
                // Gọi hàm in từ Service
                PrintingService.printInvoice(state.invoice);
              },
              icon: const Icon(Icons.print),
              label: const Text("IN PHIẾU"),
              backgroundColor: Colors.blue,
            );
          }
          return const SizedBox();
        },
      ),
      body: BlocBuilder<InvoiceDetailCubit, InvoiceDetailState>(
        builder: (context, state) {
          if (state is InvoiceDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceDetailError) {
            return Center(child: Text("Lỗi: ${state.message}"));
          }
          if (state is InvoiceDetailLoaded) {
            return _buildContent(context, state.invoice);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, InvoiceEntity invoice) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text("PHIẾU XUẤT HÀNG",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(dateFormat.format(invoice.createdDate),
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 30),

              // Info
              _buildInfoRow("Khách hàng:", invoice.partnerName ?? "Khách lẻ"),
              _buildInfoRow(
                  "Mã phiếu:", invoice.id.substring(0, 8).toUpperCase()),
              const SizedBox(height: 20),

              // Table
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FixedColumnWidth(50),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(100),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    children: const [
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("STT",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("KL (kg)",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("SL",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Giờ",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  ...invoice.details.map((item) {
                    return TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${item.sequence}")),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${item.weight}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("${item.quantity}")),
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(DateFormat('HH:mm').format(item.time))),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Footer Totals
              const Divider(),
              _buildInfoRow("Tổng trọng lượng:", "${invoice.totalWeight} kg",
                  isBold: true),
              _buildInfoRow("Tổng số con:", "${invoice.totalQuantity} con"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("THÀNH TIỀN:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(invoice.finalAmount),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}