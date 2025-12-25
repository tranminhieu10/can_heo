import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/invoice.dart';

class ReportDataTable extends StatefulWidget {
  final List<InvoiceEntity> invoices;
  final String type; // "Nhập" or "Bán"

  const ReportDataTable({
    super.key,
    required this.invoices,
    required this.type,
  });

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final TextEditingController _transportFeeController = TextEditingController(text: '0');
  final TextEditingController _weighingFeeController = TextEditingController(text: '0');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'en_US');

  @override
  void dispose() {
    _transportFeeController.dispose();
    _weighingFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoices.isEmpty) {
      return const Center(child: Text('Không có dữ liệu trong khoảng thời gian đã chọn.'));
    }
    
    // Listen to changes in text fields to rebuild the grand total
    return ListenableBuilder(
      listenable: Listenable.merge([_transportFeeController, _weighingFeeController]),
      builder: (context, child) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildDataRows(),
            ),
            _buildFooter(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 2.0)),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          _buildHeaderCell('STT', width: 40),
          _buildHeaderCell('Ngày', width: 90),
          _buildHeaderCell('SL', width: 50, isNumeric: true),
          _buildHeaderCell('TL Cân', width: 80, isNumeric: true),
          _buildHeaderCell('Bình quân', width: 80, isNumeric: true),
          _buildHeaderCell('Đơn giá', width: 100, isNumeric: true),
          _buildHeaderCell('Thành tiền', width: 120, isNumeric: true),
          _buildHeaderCell('Ghi chú', flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width, int? flex, bool isNumeric = false}) {
    final child = Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold));
    final alignment = isNumeric ? Alignment.centerRight : Alignment.centerLeft;
    
    if (flex != null) {
      return Expanded(flex: flex, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Align(alignment: alignment, child: child),
      ));
    }
    return SizedBox(width: width, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Align(alignment: alignment, child: child),
    ));
  }

  Widget _buildDataRows() {
    final dateFormat = DateFormat('dd/MM/yy');
    return ListView.builder(
      itemCount: widget.invoices.length,
      itemBuilder: (context, index) {
        final invoice = widget.invoices[index];
        final avgWeight = invoice.totalQuantity > 0 ? invoice.totalWeight / invoice.totalQuantity : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              _buildDataCell((index + 1).toString(), width: 40),
              _buildDataCell(dateFormat.format(invoice.createdDate), width: 90),
              _buildDataCell(invoice.totalQuantity.toString(), width: 50, isNumeric: true),
              _buildDataCell(_numberFormat.format(invoice.totalWeight), width: 80, isNumeric: true),
              _buildDataCell(_numberFormat.format(avgWeight), width: 80, isNumeric: true),
              _buildDataCell(_currencyFormat.format(invoice.pricePerKg), width: 100, isNumeric: true),
              _buildDataCell(_currencyFormat.format(invoice.finalAmount), width: 120, isNumeric: true, isBold: true),
              _buildDataCell(invoice.note ?? '', flex: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataCell(String text, {double? width, int? flex, bool isNumeric = false, bool isBold = false}) {
     final child = Text(
       text, 
       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
         fontWeight: isBold ? FontWeight.bold : FontWeight.normal
       ),
       overflow: TextOverflow.ellipsis,
      );
    final alignment = isNumeric ? Alignment.centerRight : Alignment.centerLeft;
    
    if (flex != null) {
      return Expanded(flex: flex, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Align(alignment: alignment, child: child),
      ));
    }
    return SizedBox(width: width, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Align(alignment: alignment, child: child),
    ));
  }

  Widget _buildFooter() {
    final double totalWeight = widget.invoices.fold<double>(0.0, (sum, inv) => sum + inv.totalWeight);
    final int totalQuantity = widget.invoices.fold<int>(0, (sum, inv) => sum + inv.totalQuantity);
    final double totalAmount = widget.invoices.fold<double>(0.0, (sum, inv) => sum + inv.finalAmount);
    
    final transportFee = double.tryParse(_transportFeeController.text.replaceAll(',', '')) ?? 0;
    final weighingFee = double.tryParse(_weighingFeeController.text.replaceAll(',', '')) ?? 0;
    
    final double grandTotal = widget.type == 'Nhập'
        ? totalAmount + transportFee + weighingFee
        : totalAmount - transportFee - weighingFee;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
             _buildTotalRow(
                'Tổng cộng', 
                '${totalQuantity} con', 
                '${_numberFormat.format(totalWeight)} kg',
                _currencyFormat.format(totalAmount)),
            const Divider(height: 24),
            _buildEditableFeeRow('Cước xe', _transportFeeController, Icons.local_shipping),
            const SizedBox(height: 8),
            _buildEditableFeeRow('Chi phí cân', _weighingFeeController, Icons.scale),
            const Divider(height: 24),
            _buildGrandTotalRow('TỔNG KẾT', grandTotal)
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String quantity, String weight, String amount) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: style),
        const SizedBox(width: 24),
        SizedBox(width: 50, child: Text(quantity, style: style, textAlign: TextAlign.right)),
        const SizedBox(width: 24),
        SizedBox(width: 90, child: Text(weight, style: style, textAlign: TextAlign.right)),
        const Spacer(),
        SizedBox(width: 120, child: Text(amount, style: style?.copyWith(color: Colors.blue.shade700), textAlign: TextAlign.right)),
        const SizedBox(width: 130) // To align with Ghi chú column
      ],
    );
  }
  
  Widget _buildEditableFeeRow(String label, TextEditingController controller, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        SizedBox(
          width: 200,
          height: 40,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              suffixText: 'đ',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 130)
      ],
    );
  }
  
  Widget _buildGrandTotalRow(String label, double total) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    final color = widget.type == 'Nhập' ? Colors.red.shade700 : Colors.green.shade700;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(
          _currencyFormat.format(total),
          style: style?.copyWith(color: color),
        ),
        const Text(' đ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 130)
      ],
    );
  }
}