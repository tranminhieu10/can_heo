import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/partner.dart';
import '../../../../domain/entities/pig_type.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_pigtype_repository.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';
import '../../partners/bloc/partner_bloc.dart';
import '../../partners/bloc/partner_state.dart';

/// Invoice form section containing all input fields for market export invoice
class InvoiceForm extends StatelessWidget {
  final bool isWeightLocked;
  final double grossWeight;
  final double netWeight;
  final double subtotal;
  final double totalAmount;
  final PartnerEntity? selectedPartner;
  final TextEditingController batchNumberController;
  final TextEditingController pigTypeController;
  final TextEditingController noteController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController deductionController;
  final TextEditingController discountController;
  final NumberFormat numberFormat;
  final NumberFormat currencyFormat;
  final VoidCallback onPartnerChanged;
  final VoidCallback onPigTypeChanged;
  final VoidCallback onQuantityChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onDeductionChanged;
  final VoidCallback onDiscountChanged;
  final VoidCallback onIncrementQuantity;
  final VoidCallback onDecrementQuantity;
  final VoidCallback onIncrementDeduction;
  final VoidCallback onDecrementDeduction;
  final VoidCallback? onAdd;
  final void Function(PartnerEntity?) setPartner;
  final void Function(String) setPigType;
  final Future<Map<String, dynamic>> Function(String) calculatePartnerDebt;

  const InvoiceForm({
    super.key,
    required this.isWeightLocked,
    required this.grossWeight,
    required this.netWeight,
    required this.subtotal,
    required this.totalAmount,
    required this.selectedPartner,
    required this.batchNumberController,
    required this.pigTypeController,
    required this.noteController,
    required this.priceController,
    required this.quantityController,
    required this.deductionController,
    required this.discountController,
    required this.numberFormat,
    required this.currencyFormat,
    required this.onPartnerChanged,
    required this.onPigTypeChanged,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onDeductionChanged,
    required this.onDiscountChanged,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
    required this.onIncrementDeduction,
    required this.onDecrementDeduction,
    required this.onAdd,
    required this.setPartner,
    required this.setPigType,
    required this.calculatePartnerDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - compact
              _buildHeader(context),
              const SizedBox(height: 6),

              // ROW 1: Mã khách hàng | Tên khách hàng | Công nợ
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: TextEditingController(
                          text: selectedPartner?.id ?? '',
                        ),
                        label: 'Mã KH',
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildPartnerSelector(context),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildPartnerDebtField(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 2: Loại heo | Số lô | Số lượng heo tồn kho
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildPigTypeWithInventory(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: batchNumberController,
                        label: 'Số lô',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildInventoryDisplayField(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 3: Số lượng (với nút +/-) | Trọng lượng | Trừ hao | TL Thực
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildQuantityFieldWithButtons(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                        label: 'Trọng lượng (kg)',
                        value: numberFormat.format(grossWeight),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildDeductionField(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                        label: 'TL Thực (kg)',
                        value: numberFormat.format(netWeight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 4: Đơn giá | Thành tiền | Chiết khấu | Thực thu
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: priceController,
                        label: 'Đơn giá (đ)',
                        isNumber: true,
                        onChanged: (_) => onPriceChanged(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                        label: 'Thành tiền',
                        value: currencyFormat.format(subtotal),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridTextField(
                        controller: discountController,
                        label: 'Chiết khấu (đ)',
                        isNumber: true,
                        onChanged: (_) => onDiscountChanged(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildGridLockedField(
                        label: 'THỰC THU',
                        value: currencyFormat.format(totalAmount),
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              // ROW 5: Ghi chú (full width)
              _buildGridTextField(
                controller: noteController,
                label: 'Ghi chú',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'THÔNG TIN PHIẾU XUẤT CHỢ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWeightLocked ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWeightLocked ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color:
                        isWeightLocked ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isWeightLocked ? 'Đã chốt' : 'Chưa chốt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isWeightLocked ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add Button
            SizedBox(
              height: 36,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('THÊM', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        border: const OutlineInputBorder(),
        isDense: true,
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildGridLockedField({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.grey[100],
        border: Border.all(
          color: highlight ? Colors.blue : Colors.grey[400]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? Colors.blue[700] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: highlight ? Colors.blue[800] : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSelector(BuildContext context) {
    return SizedBox(
      height: 46,
      child: BlocBuilder<PartnerBloc, PartnerState>(
        builder: (context, state) {
          final partners = state.partners;
          final safeValue =
              (partners.contains(selectedPartner)) ? selectedPartner : null;

          return DropdownButtonFormField<PartnerEntity>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khách hàng',
              labelStyle: TextStyle(fontSize: 10),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            value: safeValue,
            style: const TextStyle(fontSize: 13, color: Colors.black),
            items: partners
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (value) {
              setPartner(value);
              onPartnerChanged();
            },
          );
        },
      ),
    );
  }

  Widget _buildPartnerDebtField() {
    if (selectedPartner == null) {
      return _buildGridLockedField(
        label: 'Công nợ',
        value: '0 đ',
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: calculatePartnerDebt(selectedPartner!.id),
      builder: (context, snapshot) {
        final debtInfo = snapshot.data ?? {};
        final remaining = debtInfo['remaining'] ?? 0.0;

        return _buildGridLockedField(
          label: 'Công nợ',
          value: currencyFormat.format(remaining),
          highlight: remaining > 0,
        );
      },
    );
  }

  Widget _buildPigTypeWithInventory() {
    return StreamBuilder<List<PigTypeEntity>>(
      stream: sl<IPigTypeRepository>().watchPigTypes(),
      builder: (context, snap) {
        final types = snap.data ?? [];
        final PigTypeEntity? selected = types.isEmpty
            ? null
            : types.firstWhere(
                (t) => t.name == pigTypeController.text,
                orElse: () => types.first,
              );

        return StreamBuilder<List<InvoiceEntity>>(
          stream: sl<IInvoiceRepository>().watchInvoices(type: 0),
          builder: (context, importSnap) {
            return StreamBuilder<List<InvoiceEntity>>(
              stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
              builder: (context, exportSnap) {
                // Calculate inventory for each pig type
                Map<String, int> inventory = {};
                for (final type in types) {
                  final pigType = type.name;
                  final importInvoices = importSnap.data ?? [];
                  final exportInvoices = exportSnap.data ?? [];

                  int imported = 0;
                  int exported = 0;

                  for (final inv in importInvoices) {
                    for (final item in inv.details) {
                      if ((item.pigType ?? '').trim() == pigType) {
                        imported += item.quantity;
                      }
                    }
                  }

                  for (final inv in exportInvoices) {
                    for (final item in inv.details) {
                      if ((item.pigType ?? '').trim() == pigType) {
                        exported += item.quantity;
                      }
                    }
                  }

                  inventory[pigType] = imported - exported;
                }

                return DropdownButtonFormField<PigTypeEntity?>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Loại heo',
                    labelStyle: TextStyle(fontSize: 10),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: types.map((type) {
                    final inv = inventory[type.name] ?? 0;
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.name} (Tồn: $inv)',
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setPigType(v.name);
                      onPigTypeChanged();
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryDisplayField() {
    final pigType = pigTypeController.text.trim();

    if (pigType.isEmpty) {
      return _buildInventoryContainer(0, true);
    }

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: sl<IInvoiceRepository>().watchInvoices(type: 0),
        builder: (context, importSnap) {
          if (!importSnap.hasData) {
            return _buildInventoryContainer(0, true);
          }

          return StreamBuilder<List<InvoiceEntity>>(
            stream: sl<IInvoiceRepository>().watchInvoices(type: 2),
            builder: (context, exportSnap) {
              if (!exportSnap.hasData) {
                return _buildInventoryContainer(0, true);
              }

              int imported = 0;
              int exported = 0;

              for (final inv in importSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    imported += item.quantity;
                  }
                }
              }

              for (final inv in exportSnap.data!) {
                for (final item in inv.details) {
                  if ((item.pigType ?? '').trim() == pigType) {
                    exported += item.quantity;
                  }
                }
              }

              final availableQty = imported - exported;
              final requestedQty = int.tryParse(quantityController.text) ?? 0;
              final isValid = requestedQty <= availableQty;

              return _buildInventoryContainer(availableQty, isValid);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryContainer(int qty, bool isValid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tồn kho',
            style: TextStyle(
              fontSize: 10,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            '$qty con',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityFieldWithButtons() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => onQuantityChanged(),
            decoration: const InputDecoration(
              labelText: 'Số lượng',
              labelStyle: TextStyle(fontSize: 10),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onIncrementQuantity,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_up, size: 12),
                  ),
                ),
              ),
              InkWell(
                onTap: onDecrementQuantity,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_down, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: deductionController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => onDeductionChanged(),
            decoration: const InputDecoration(
              labelText: 'Trừ hao (kg)',
              labelStyle: TextStyle(fontSize: 10),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onIncrementDeduction,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_up, size: 12),
                  ),
                ),
              ),
              InkWell(
                onTap: onDecrementDeduction,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.keyboard_arrow_down, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
