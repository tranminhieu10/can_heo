import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Cần thêm intl vào pubspec.yaml nếu chưa có

import '../../../../core/constants/enums.dart'; // Import Enum InvoiceType
import '../../../../domain/entities/invoice.dart';
import '../../../../injection_container.dart'; // Để lấy sl (Service Locator)
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';

class MarketExportScreen extends StatelessWidget {
  const MarketExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp WeighingBloc cho màn hình này
    return BlocProvider(
      create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(2)), // 2 = InvoiceType.exportMarket (Hardcode tạm, sau này dùng Enum index)
      child: const _MarketExportView(),
    );
  }
}

class _MarketExportView extends StatefulWidget {
  const _MarketExportView();

  @override
  State<_MarketExportView> createState() => _MarketExportViewState();
}

class _MarketExportViewState extends State<_MarketExportView> {
  // Controller cho các ô nhập liệu
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _truckCostController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final NumberFormat _numberFormat = NumberFormat("#,##0.0", "en_US");

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _truckCostController.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("XUẤT CHỢ"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút Lưu Phiếu
          BlocBuilder<WeighingBloc, WeighingState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: FilledButton.icon(
                  onPressed: state.items.isEmpty
                      ? null
                      : () {
                          context.read<WeighingBloc>().add(WeighingSaved());
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đang lưu phiếu...")));
                        },
                  icon: const Icon(Icons.save),
                  label: const Text("LƯU PHIẾU"),
                ),
              );
            },
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================
          // CỘT TRÁI: KHU VỰC CÂN & NHẬP
          // ==============================
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInputPanel(context),
                  const SizedBox(height: 16),
                  _buildKeypad(context),
                ],
              ),
            ),
          ),

          // ==============================
          // CỘT PHẢI: PHIẾU & DANH SÁCH
          // ==============================
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  _buildInvoiceHeader(),
                  const Divider(height: 1),
                  Expanded(child: _buildWeighingList()),
                  const Divider(height: 1),
                  _buildInvoiceFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Khu vực nhập cân ---
  Widget _buildInputPanel(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("MÔ PHỎNG CÂN (Sau này kết nối Serial)",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: "KG",
                border: OutlineInputBorder(),
                hintText: "0.0",
              ),
              onSubmitted: (_) => _submitWeight(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => _submitWeight(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("GHI CÂN (ENTER)", style: TextStyle(fontSize: 20)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Widget: Bàn phím số ảo (Nếu dùng màn hình cảm ứng) ---
  Widget _buildKeypad(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.white, // Placeholder cho bàn phím số
        child: const Center(child: Text("Khu vực bàn phím số / Chọn khách hàng")),
      ),
    );
  }

  // --- Widget: Header Phiếu (Thông tin chung) ---
  Widget _buildInvoiceHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<WeighingBloc, WeighingState>(
        builder: (context, state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("KHÁCH HÀNG: Nguyễn Văn A (Mẫu)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Tổng KL: ${_numberFormat.format(state.currentInvoice?.totalWeight ?? 0)} kg",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                  Text("Tổng con: ${state.currentInvoice?.totalQuantity ?? 0}",
                      style: const TextStyle(fontSize: 16)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  // --- Widget: Danh sách mã cân (Table) ---
  Widget _buildWeighingList() {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const Center(child: Text("Chưa có mã cân nào", style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text("${item.sequence}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text("${_numberFormat.format(item.weight)} kg", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text("${item.quantity} con")),
                  SizedBox(width: 100, child: Text(DateFormat('HH:mm:ss').format(item.time), style: const TextStyle(color: Colors.grey))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Widget: Footer tính tiền ---
  Widget _buildInvoiceFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Đơn giá (đ/kg)", border: OutlineInputBorder()),
                  onChanged: (val) => setState(() {}), // Refresh để tính lại tổng
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _truckCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Cước xe (đ)", border: OutlineInputBorder()),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<WeighingBloc, WeighingState>(
            builder: (context, state) {
              // Tính toán sơ bộ trên UI (Logic chính thức nên đưa vào Bloc)
              double price = double.tryParse(_priceController.text) ?? 0;
              double truck = double.tryParse(_truckCostController.text) ?? 0;
              double totalWeight = state.currentInvoice?.totalWeight ?? 0;
              double totalMoney = (totalWeight * price) + truck;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("THÀNH TIỀN:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_currencyFormat.format(totalMoney),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  void _submitWeight(BuildContext context) {
    final text = _weightController.text;
    if (text.isEmpty) return;

    final weight = double.tryParse(text);
    if (weight != null && weight > 0) {
      // Gửi sự kiện thêm cân vào Bloc
      context.read<WeighingBloc>().add(WeighingItemAdded(weight: weight));
      
      // Clear input và focus lại để nhập tiếp
      _weightController.clear();
      _weightFocus.requestFocus();
    }
  }
}