import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/entities/additional_cost.dart';

/// Widget quản lý 1 phiên cân (nhiều lần cân)
class WeighingSessionWidget extends StatefulWidget {
  final String partnerName;
  final String? selectedFarmId;
  final String? selectedFarmName;
  final Function(List<WeighingItemEntity>, List<AdditionalCost>) onSave;
  final VoidCallback onCancel;

  const WeighingSessionWidget({
    super.key,
    required this.partnerName,
    this.selectedFarmId,
    this.selectedFarmName,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<WeighingSessionWidget> createState() => _WeighingSessionWidgetState();
}

class _WeighingSessionWidgetState extends State<WeighingSessionWidget> {
  final List<WeighingItemEntity> _weighingItems = [];
  final List<AdditionalCost> _additionalCosts = [];
  
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _pigTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  
  bool _isFinalized = false; // Đã chốt chưa
  
  @override
  void dispose() {
    _weightController.dispose();
    _quantityController.dispose();
    _batchController.dispose();
    _pigTypeController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  // Tính tổng
  double get _totalWeight => _weighingItems.fold(0.0, (sum, item) => sum + item.weight);
  int get _totalQuantity => _weighingItems.fold(0, (sum, item) => sum + item.quantity);
  double get _totalAdditionalCost => _additionalCosts.fold(0.0, (sum, cost) => sum + cost.amount);
  
  // Tính tổng thành tiền (weight × pricePerKg cho mỗi item)
  double get _totalAmount => _weighingItems.fold(0.0, (sum, item) {
    // Lấy pricePerKg từ batchNumber tạm thời (sẽ parse từ format "batch|pigType|price")
    final parts = (item.batchNumber ?? '||0').split('|');
    final price = double.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
    return sum + (item.weight * price);
  });
  
  // Tính đơn giá bình quân
  double get _averagePrice => _totalWeight > 0 ? _totalAmount / _totalWeight : 0;
  
  void _addWeighingItem() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final pigType = _pigTypeController.text.trim();
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    
    if (weight <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng nhập cân nặng và số lượng hợp lệ')),
      );
      return;
    }
    
    if (pigType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng nhập loại heo')),
      );
      return;
    }
    
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng nhập đơn giá')),
      );
      return;
    }
    
    // Lưu thông tin vào batchNumber theo format: "batch|pigType|price"
    final batchData = '${_batchController.text}|$pigType|$price';
    
    final item = WeighingItemEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sequence: _weighingItems.length + 1,
      weight: weight,
      quantity: quantity,
      time: DateTime.now(),
      batchNumber: batchData,
      pigType: pigType,
    );
    
    setState(() {
      _weighingItems.add(item);
      _weightController.clear();
      _quantityController.text = '1';
      // Giữ lại Loại heo và Đơn giá để tiện nhập tiếp
    });
  }
  
  void _removeWeighingItem(int index) {
    setState(() {
      _weighingItems.removeAt(index);
      // Cập nhật lại sequence
      for (int i = 0; i < _weighingItems.length; i++) {
        _weighingItems[i] = _weighingItems[i].copyWith(sequence: i + 1);
      }
    });
  }
  
  void _finalizeWeighing() {
    if (_weighingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Chưa có lần cân nào')),
      );
      return;
    }
    
    setState(() {
      _isFinalized = true;
    });
  }
  
  void _addAdditionalCost() {
    showDialog(
      context: context,
      builder: (context) => _AddCostDialog(
        onAdd: (cost) {
          setState(() {
            _additionalCosts.add(cost);
          });
        },
      ),
    );
  }
  
  void _removeAdditionalCost(int index) {
    setState(() {
      _additionalCosts.removeAt(index);
    });
  }
  
  void _save() {
    if (_weighingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Chưa có lần cân nào')),
      );
      return;
    }
    
    widget.onSave(_weighingItems, _additionalCosts);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.scale, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PHIÊN CÂN - ${widget.partnerName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _isFinalized
              ? _buildFinalizedView()
              : _buildWeighingView(),
        ),
      ],
    );
  }
  
  Widget _buildWeighingView() {
    return Column(
      children: [
        // Form nhập cân - Tối ưu cho nhập tay
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập thông tin lần cân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dòng 1: Trọng lượng + Số lượng + Lô
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _weightController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg) *',
                            hintText: 'Nhập kg',
                            prefixIcon: Icon(Icons.scale),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          onSubmitted: (_) => _addWeighingItem(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Số lượng *',
                            hintText: 'Số con',
                            prefixIcon: Icon(Icons.pets),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          onSubmitted: (_) => _addWeighingItem(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _batchController,
                          decoration: const InputDecoration(
                            labelText: 'Số lô',
                            hintText: 'VD: Lô 123',
                            prefixIcon: Icon(Icons.tag),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _addWeighingItem(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dòng 2: Loại heo + Đơn giá + Nút Thêm
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _pigTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Loại heo *',
                            hintText: 'VD: Nái, Heo thịt',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _addWeighingItem(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Đơn giá (đ/kg) *',
                            hintText: 'VD: 65000',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _addWeighingItem(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _addWeighingItem,
                            icon: const Icon(Icons.add_circle, size: 24),
                            label: const Text('THÊM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bảng các lần cân
        Expanded(
          child: _weighingItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có lần cân nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập cân nặng và số lượng, sau đó bấm "THÊM"',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 50, child: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Expanded(flex: 2, child: Text('Cân nặng (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Expanded(flex: 2, child: Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Expanded(flex: 3, child: Text('Số lô', style: TextStyle(fontWeight: FontWeight.bold))),
                            const SizedBox(width: 60, child: Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      // Body
                      Expanded(
                        child: ListView.builder(
                          itemCount: _weighingItems.length,
                          itemBuilder: (context, index) {
                            final item = _weighingItems[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              ),
                              child: ListTile(
                                dense: true,
                                leading: SizedBox(
                                  width: 50,
                                  child: Center(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue.shade600,
                                      radius: 16,
                                      child: Text(
                                        '${item.sequence}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${_numberFormat.format(item.weight)} kg',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${item.quantity} con',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.batchNumber ?? '-',
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 60,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeWeighingItem(index),
                                    tooltip: 'Xóa',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        
        // Tổng kết và nút chốt
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildSummaryItem('Số lần cân', '${_weighingItems.length}', Colors.blue),
                  const SizedBox(width: 12),
                  _buildSummaryItem('Tổng SL', '$_totalQuantity con', Colors.orange),
                  const SizedBox(width: 12),
                  _buildSummaryItem('Tổng TL', '${_numberFormat.format(_totalWeight)} kg', Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_weighingItems.isEmpty) {
                          widget.onCancel();
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận'),
                              content: const Text('Bạn có chắc muốn hủy? Dữ liệu đã nhập sẽ bị mất.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Không'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onCancel();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Có, hủy bỏ'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('HỦY'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _weighingItems.isEmpty ? null : _finalizeWeighing,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text('CHỐT & TIẾP TỤC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinalizedView() {
    return Column(
      children: [
        // Bảng tổng hợp các lần cân
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: const Text(
                    'TỔNG HỢP CÁC LẦN CÂN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Lô', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Loại heo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('KL (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Đơn giá (đ/kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _weighingItems.map((item) {
                          // Parse data từ batchNumber: "batch|pigType|price"
                          final parts = (item.batchNumber ?? '||0').split('|');
                          final batch = parts.isNotEmpty ? parts[0] : '';
                          final pigType = parts.length > 1 ? parts[1] : '';
                          final price = double.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
                          final subtotal = item.weight * price;
                          
                          return DataRow(cells: [
                            DataCell(Text('${item.sequence}', style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(batch)),
                            DataCell(Text(pigType, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500))),
                            DataCell(Text(_numberFormat.format(item.weight), style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text('${item.quantity}')),
                            DataCell(Text(NumberFormat('#,###').format(price))),
                            DataCell(Text(
                              NumberFormat('#,###').format(subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng KL: ${_numberFormat.format(_totalWeight)} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Tổng SL: $_totalQuantity con',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(height: 8, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng thành tiền:',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          Text(
                            NumberFormat('#,###').format(_totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn giá bình quân:',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(_averagePrice)} đ/kg',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Phần chi phí khác
        Expanded(
          flex: 1,
          child: Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      const Text(
                        'CHI PHÍ KHÁC',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addAdditionalCost,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Thêm'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _additionalCosts.isEmpty
                      ? const Center(child: Text('Chưa có chi phí nào'))
                      : ListView.builder(
                          itemCount: _additionalCosts.length,
                          itemBuilder: (context, index) {
                            final cost = _additionalCosts[index];
                            return ListTile(
                              title: Text(cost.label),
                              subtitle: cost.quantity != null && cost.weight != null
                                  ? Text('${cost.quantity} con - ${_numberFormat.format(cost.weight!)} kg')
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currencyFormat.format(cost.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _removeAdditionalCost(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_additionalCosts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tổng chi phí: ${_currencyFormat.format(_totalAdditionalCost)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Nút lưu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isFinalized = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('LƯU PHIẾU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCostDialog extends StatefulWidget {
  final Function(AdditionalCost) onAdd;

  const _AddCostDialog({required this.onAdd});

  @override
  State<_AddCostDialog> createState() => _AddCostDialogState();
}

class _AddCostDialogState extends State<_AddCostDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  String _costType = 'simple'; // 'simple' or 'detailed' (lợn chết)
  
  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  void _add() {
    final label = _labelController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    
    if (label.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }
    
    final cost = AdditionalCost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      amount: amount,
      quantity: _costType == 'detailed' ? int.tryParse(_quantityController.text) : null,
      weight: _costType == 'detailed' ? double.tryParse(_weightController.text) : null,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    
    widget.onAdd(cost);
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Chi Phí'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loại chi phí
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'simple', label: Text('Đơn giản'), icon: Icon(Icons.money)),
                ButtonSegment(value: 'detailed', label: Text('Lợn chết'), icon: Icon(Icons.pets)),
              ],
              selected: {_costType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _costType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Tên chi phí
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Tên chi phí',
                hintText: _costType == 'simple' ? 'VD: Cước xe' : 'VD: Lợn chết',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Nếu là lợn chết, hiện thêm số lượng và cân nặng
            if (_costType == 'detailed') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Thành tiền
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Thành tiền (₫)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Ghi chú
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _add,
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
