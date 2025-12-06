import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 

import '../../../../core/constants/enums.dart'; 
import '../../../../injection_container.dart'; 
import '../weighing/bloc/weighing_bloc.dart';
import '../weighing/bloc/weighing_event.dart';
import '../weighing/bloc/weighing_state.dart';

class MarketExportScreen extends StatelessWidget {
  const MarketExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WeighingBloc>()..add(const WeighingStarted(2)), // 2 = Xuất Chợ
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
    return BlocListener<WeighingBloc, WeighingState>(
      listener: (context, state) {
        if (state.status == WeighingStatus.success) {
          // --- XỬ LÝ KHI LƯU THÀNH CÔNG ---
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã lưu phiếu thành công!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Reset Input
          _weightController.clear();
          _priceController.clear();
          _truckCostController.clear();
          
          // Focus lại ô cân để làm phiếu tiếp theo
          _weightFocus.requestFocus();

          // Tạo phiếu mới
          context.read<WeighingBloc>().add(const WeighingStarted(2)); 
        } else if (state.status == WeighingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Lỗi: ${state.errorMessage}"), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("XUẤT CHỢ"),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            BlocBuilder<WeighingBloc, WeighingState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FilledButton.icon(
                    // Disable nút nếu chưa có mã cân nào
                    onPressed: state.items.isEmpty
                        ? null
                        : () {
                            context.read<WeighingBloc>().add(WeighingSaved());
                          },
                    icon: const Icon(Icons.save),
                    label: const Text("LƯU PHIẾU"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                );
              },
            )
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CỘT TRÁI: NHẬP LIỆU
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInputPanel(context),
                    // Có thể thêm bàn phím số ảo ở đây nếu cần
                  ],
                ),
              ),
            ),

            // CỘT PHẢI: PHIẾU & DANH SÁCH
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
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("NHẬP TRỌNG LƯỢNG",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: "KG",
                border: OutlineInputBorder(),
                hintText: "0.0",
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
              onSubmitted: (_) => _submitWeight(context),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _submitWeight(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: const Text("GHI CÂN (ENTER)", style: TextStyle(fontSize: 20)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
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
                  const SizedBox(height: 4),
                  Text("Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Tổng KL: ${_numberFormat.format(state.currentInvoice?.totalWeight ?? 0)} kg",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                  Text("Số lượng: ${state.currentInvoice?.totalQuantity ?? 0} con",
                      style: const TextStyle(fontSize: 16)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeighingList() {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Chưa có mã cân nào", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return Container(
              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: Text("${item.sequence}", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text("${_numberFormat.format(item.weight)} kg", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text("${item.quantity} con", style: const TextStyle(color: Colors.grey))),
                  Text(DateFormat('HH:mm').format(item.time), style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Đơn giá (đ/kg)", 
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) => _updateInvoiceCalculations(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _truckCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Cước xe (đ)", 
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) => _updateInvoiceCalculations(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<WeighingBloc, WeighingState>(
            builder: (context, state) {
              final money = state.currentInvoice?.finalAmount ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("THÀNH TIỀN:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text(_currencyFormat.format(money),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
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
      context.read<WeighingBloc>().add(WeighingItemAdded(weight: weight));
      _weightController.clear();
      _weightFocus.requestFocus();
    }
  }

  void _updateInvoiceCalculations(BuildContext context) {
    // Loại bỏ các ký tự không phải số nếu cần (ví dụ dấu phẩy)
    double price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    double truck = double.tryParse(_truckCostController.text.replaceAll(',', '')) ?? 0;
    
    context.read<WeighingBloc>().add(WeighingInvoiceUpdated(
      pricePerKg: price,
      truckCost: truck,
    ));
  }
}