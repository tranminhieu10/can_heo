import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/scale_service.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';
import '../../weighing/bloc/weighing_bloc.dart';
import '../../weighing/bloc/weighing_state.dart';

class ScaleSection extends StatelessWidget {
  final bool isWeightLocked;
  final double lockedWeight;
  final VoidCallback onTare;
  final VoidCallback onLockWeight;
  final NumberFormat numberFormat;
  final NumberFormat currencyFormat;

  const ScaleSection({
    super.key,
    required this.isWeightLocked,
    required this.lockedWeight,
    required this.onTare,
    required this.onLockWeight,
    required this.numberFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeighingBloc, WeighingState>(
      builder: (context, state) {
        final weight = state.scaleWeight;
        final connected = state.isScaleConnected;

        return Card(
          color: isWeightLocked ? Colors.green[50] : Colors.blue[50],
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ROW 1: Scale display
                  _buildScaleDisplay(connected, weight),
                  const SizedBox(height: 8),

                  // ROW 2: TARE and Lock buttons
                  _buildButtons(connected, weight),
                  const SizedBox(height: 8),

                  // ROW 3-5: Summary rows
                  _ScaleSummaryRow(
                    label: 'TỔNG SỐ HEO BÁN',
                    icon: Icons.pets,
                    color: Colors.orange,
                    numberFormat: numberFormat,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(height: 8),
                  _ScaleSummaryRow(
                    label: 'TỔNG KHỐI LƯỢNG',
                    icon: Icons.scale,
                    color: Colors.blue,
                    numberFormat: numberFormat,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(height: 8),
                  _ScaleSummaryRow(
                    label: 'TỔNG TIỀN',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    numberFormat: numberFormat,
                    currencyFormat: currencyFormat,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleDisplay(bool connected, double weight) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWeightLocked ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWeightLocked ? 'ĐÃ CHỐT CÂN' : 'SỐ CÂN (kg)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isWeightLocked ? Colors.green[700] : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWeightLocked
                ? numberFormat.format(lockedWeight)
                : (connected ? numberFormat.format(weight) : 'Mất kết nối'),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isWeightLocked
                  ? Colors.green[800]
                  : (connected ? Colors.blue[800] : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(bool connected, double weight) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: connected ? onTare : null,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('TARE', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: (connected && weight > 0) ? onLockWeight : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: isWeightLocked ? Colors.green : null,
              ),
              child: Text(
                isWeightLocked ? 'HỦY CHỐT' : 'CHỐT CÂN',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleSummaryRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final NumberFormat numberFormat;
  final NumberFormat currencyFormat;

  const _ScaleSummaryRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.numberFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return RepaintBoundary(
      child: StreamBuilder<List<InvoiceEntity>>(
        stream: invoiceRepo.watchInvoices(type: 2),
        builder: (context, snapshot) {
          String value = '0';

          if (snapshot.hasData) {
            final invoices = snapshot.data!;
            final today = DateTime.now();
            final todayInvoices = invoices.where((inv) {
              return inv.createdDate.year == today.year &&
                  inv.createdDate.month == today.month &&
                  inv.createdDate.day == today.day;
            }).toList();

            double totalWeight = 0;
            int totalQuantity = 0;
            double totalAmount = 0;

            for (final inv in todayInvoices) {
              totalWeight += inv.totalWeight;
              totalQuantity += inv.totalQuantity;
              totalAmount += inv.finalAmount;
            }

            if (label.contains('SỐ HEO')) {
              value = '$totalQuantity con';
            } else if (label.contains('KHỐI LƯỢNG')) {
              value = '${numberFormat.format(totalWeight)} kg';
            } else {
              value = currencyFormat.format(totalAmount);
            }
          }

          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
