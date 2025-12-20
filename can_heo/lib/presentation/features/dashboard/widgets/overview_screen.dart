import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _refreshKey = 0;

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(onRefresh: _refresh),
              const SizedBox(height: 16),
              _TodayStatsSection(key: ValueKey('stats_$_refreshKey')),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _WeeklyChartSection(
                            key: ValueKey('chart_$_refreshKey')),
                        const SizedBox(height: 16),
                        _RecentTransactionsSection(
                            key: ValueKey('transactions_$_refreshKey')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _BarnInventorySection(
                            key: ValueKey('barn_$_refreshKey')),
                        const SizedBox(height: 16),
                        _MarketInventorySection(
                            key: ValueKey('market_$_refreshKey')),
                        const SizedBox(height: 16),
                        _TopPartnersSection(
                            key: ValueKey('partners_$_refreshKey')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HEADER ====================
class _HeaderSection extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HeaderSection({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Tổng quan',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(now),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.refresh,
              label: 'Làm mới',
              onTap: onRefresh,
            ),
            const SizedBox(width: 8),
            _QuickActionButton(
              icon: Icons.download,
              label: 'Xuất báo cáo',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ==================== TODAY STATS ====================
class _TodayStatsSection extends StatelessWidget {
  const _TodayStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return StreamBuilder<List<List<InvoiceEntity>>>(
      stream: Rx.combineLatest4(
        invoiceRepo.watchInvoices(type: 0, daysAgo: 0),
        invoiceRepo.watchInvoices(type: 2, daysAgo: 0),
        invoiceRepo.watchInvoices(type: 3, daysAgo: 0),
        invoiceRepo.watchInvoices(type: 1, daysAgo: 0),
        (a, b, c, d) => [a, b, c, d],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final importBarn = snapshot.data![0];
        final exportMarket = snapshot.data![1];
        final importMarket = snapshot.data![2];

        double totalRevenue = 0;
        double totalCost = 0;
        int totalPigs = 0;

        for (final inv in exportMarket) {
          totalRevenue += inv.finalAmount;
          totalPigs += inv.totalQuantity;
        }

        for (final inv in importBarn) {
          totalCost += inv.finalAmount;
        }

        for (final inv in importMarket) {
          totalCost += inv.finalAmount;
        }

        final totalProfit = totalRevenue - totalCost;

        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final startOfYesterday =
            DateTime(yesterday.year, yesterday.month, yesterday.day);
        final endOfYesterday = startOfYesterday.add(const Duration(days: 1));

        double yesterdayRevenue = 0;
        double yesterdayCost = 0;
        int yesterdayPigs = 0;

        for (final inv in exportMarket) {
          if (inv.createdDate.isAfter(startOfYesterday) &&
              inv.createdDate.isBefore(endOfYesterday)) {
            yesterdayRevenue += inv.finalAmount;
            yesterdayPigs += inv.totalQuantity;
          }
        }

        for (final inv in importBarn) {
          if (inv.createdDate.isAfter(startOfYesterday) &&
              inv.createdDate.isBefore(endOfYesterday)) {
            yesterdayCost += inv.finalAmount;
          }
        }

        for (final inv in importMarket) {
          if (inv.createdDate.isAfter(startOfYesterday) &&
              inv.createdDate.isBefore(endOfYesterday)) {
            yesterdayCost += inv.finalAmount;
          }
        }

        final yesterdayProfit = yesterdayRevenue - yesterdayCost;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Doanh thu',
                value: _formatCurrency(totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
                trend: _calculateTrend(totalRevenue, yesterdayRevenue),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Chi phí',
                value: _formatCurrency(totalCost),
                icon: Icons.money_off,
                color: Colors.orange,
                trend: _calculateTrend(totalCost, yesterdayCost),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Lợi nhuận',
                value: _formatCurrency(totalProfit),
                icon: Icons.trending_up,
                color: totalProfit >= 0 ? Colors.blue : Colors.red,
                trend: _calculateTrend(totalProfit, yesterdayProfit),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Số con đã bán',
                value: totalPigs.toString(),
                icon: Icons.pets,
                color: Colors.purple,
                trend: totalPigs > yesterdayPigs
                    ? '+${totalPigs - yesterdayPigs} con'
                    : '${totalPigs - yesterdayPigs} con',
                isInteger: true,
              ),
            ),
          ],
        );
      },
    );
  }

  String _calculateTrend(double today, double yesterday) {
    if (yesterday == 0) {
      return today > 0 ? '+100%' : '0%';
    }
    final percent = ((today - yesterday) / yesterday * 100);
    return percent >= 0
        ? '+${percent.toStringAsFixed(1)}%'
        : '${percent.toStringAsFixed(1)}%';
  }

  String _formatCurrency(double value) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(value);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isInteger;

  const _StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WEEKLY CHART ====================
class _WeeklyChartSection extends StatelessWidget {
  const _WeeklyChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📈 Doanh thu 7 ngày qua',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: '7 ngày',
                items: const [
                  DropdownMenuItem(value: '7 ngày', child: Text('7 ngày')),
                  DropdownMenuItem(value: '30 ngày', child: Text('30 ngày')),
                  DropdownMenuItem(value: '90 ngày', child: Text('90 ngày')),
                ],
                onChanged: (value) {},
                underline: const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: StreamBuilder<List<InvoiceEntity>>(
              stream: invoiceRepo.watchInvoices(type: 2),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoices = snapshot.data!;
                final now = DateTime.now();
                final List<double> dailyRevenue = List.filled(7, 0.0);
                final List<String> dayLabels = [];

                for (int i = 6; i >= 0; i--) {
                  final targetDate = now.subtract(Duration(days: i));
                  final startOfDay = DateTime(
                      targetDate.year, targetDate.month, targetDate.day);
                  final endOfDay = startOfDay.add(const Duration(days: 1));

                  double dayTotal = 0;
                  for (final inv in invoices) {
                    if (inv.createdDate.isAfter(startOfDay) &&
                        inv.createdDate.isBefore(endOfDay)) {
                      dayTotal += inv.finalAmount;
                    }
                  }

                  dailyRevenue[6 - i] = dayTotal;
                  final weekday = [
                    'CN',
                    'T2',
                    'T3',
                    'T4',
                    'T5',
                    'T6',
                    'T7'
                  ][targetDate.weekday % 7];
                  dayLabels.add(weekday);
                }

                return _SimpleBarChart(data: dailyRevenue, labels: dayLabels);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const _SimpleBarChart({super.key, required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return const Center(
        child: Text('Chưa có dữ liệu doanh thu',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(data.length, (index) {
        final value = data[index];
        final height = maxValue > 0 ? (value / maxValue) * 170 : 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatValue(value),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: (height.clamp(2.0, 170.0) as double),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.blue, Colors.blue.shade300],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        );
      }),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else if (value == 0) {
      return '0';
    }
    return value.toStringAsFixed(0);
  }
}

// ==================== BARN INVENTORY ====================
class _BarnInventorySection extends StatelessWidget {
  const _BarnInventorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📦 Tồn kho (Trại)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest2(
              invoiceRepo.watchInvoices(type: 0),
              invoiceRepo.watchInvoices(type: 1),
              (a, b) => [a, b],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final importBarn = snapshot.data![0];
              final exportBarn = snapshot.data![1];

              Map<String, int> inventory = {};

              for (final inv in importBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) + detail.quantity;
                }
              }

              for (final inv in exportBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) - detail.quantity;
                }
              }

              final sortedInventory = inventory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (sortedInventory.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có dữ liệu tồn kho',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: sortedInventory.take(5).map((entry) {
                  return _InventoryItem(
                    name: entry.key,
                    quantity: entry.value,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== MARKET INVENTORY ====================
class _MarketInventorySection extends StatelessWidget {
  const _MarketInventorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛒 Tồn chợ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest2(
              invoiceRepo.watchInvoices(type: 3),
              invoiceRepo.watchInvoices(type: 2),
              (a, b) => [a, b],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final importMarket = snapshot.data![0];
              final exportMarket = snapshot.data![1];

              Map<String, int> inventory = {};

              for (final inv in importMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) + detail.quantity;
                }
              }

              for (final inv in exportMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) - detail.quantity;
                }
              }

              final sortedInventory = inventory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (sortedInventory.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có dữ liệu tồn chợ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: sortedInventory.take(5).map((entry) {
                  return _InventoryItem(
                    name: entry.key,
                    quantity: entry.value,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final String name;
  final int quantity;

  const _InventoryItem({
    super.key,
    required this.name,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final color = quantity > 50
        ? Colors.green
        : quantity > 20
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$quantity con',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TOP PARTNERS ====================
class _TopPartnersSection extends StatelessWidget {
  const _TopPartnersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Top khách hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<InvoiceEntity>>(
            stream: invoiceRepo.watchInvoices(type: 2),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = snapshot.data!;
              Map<String, double> partnerRevenue = {};

              for (final inv in invoices) {
                final partner = inv.partnerName ?? 'Khách lẻ';
                partnerRevenue[partner] =
                    (partnerRevenue[partner] ?? 0) + inv.finalAmount;
              }

              final sortedPartners = partnerRevenue.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (sortedPartners.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có dữ liệu khách hàng',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: sortedPartners.take(5).map((entry) {
                  final rank = sortedPartners.indexOf(entry) + 1;
                  return _PartnerItem(
                    rank: rank,
                    name: entry.key,
                    revenue: entry.value,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PartnerItem extends StatelessWidget {
  final int rank;
  final String name;
  final double revenue;

  const _PartnerItem({
    super.key,
    required this.rank,
    required this.name,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final rankColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey[400]
            : rank == 3
                ? Colors.brown[300]
                : Colors.grey[300];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatter.format(revenue),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== RECENT TRANSACTIONS ====================
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🕐 Giao dịch gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest4(
              invoiceRepo.watchInvoices(type: 0),
              invoiceRepo.watchInvoices(type: 1),
              invoiceRepo.watchInvoices(type: 2),
              invoiceRepo.watchInvoices(type: 3),
              (a, b, c, d) => [a, b, c, d],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allInvoices = <InvoiceEntity>[
                ...snapshot.data![0],
                ...snapshot.data![1],
                ...snapshot.data![2],
                ...snapshot.data![3],
              ];

              allInvoices
                  .sort((a, b) => b.createdDate.compareTo(a.createdDate));

              if (allInvoices.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: allInvoices.take(8).map((invoice) {
                  return _TransactionItem(invoice: invoice);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final InvoiceEntity invoice;

  const _TransactionItem({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM HH:mm');

    final typeInfo = _getTypeInfo(invoice.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeInfo['icon'],
              color: typeInfo['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeInfo['label'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  invoice.partnerName ?? 'Không rõ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(invoice.finalAmount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: typeInfo['color'],
                ),
              ),
              Text(
                dateFormat.format(invoice.createdDate),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(int type) {
    switch (type) {
      case 0:
        return {'label': 'Nhập kho', 'icon': Icons.input, 'color': Colors.blue};
      case 1:
        return {
          'label': 'Xuất kho',
          'icon': Icons.outbox,
          'color': Colors.orange
        };
      case 2:
        return {
          'label': 'Xuất chợ',
          'icon': Icons.storefront,
          'color': Colors.green
        };
      case 3:
        return {
          'label': 'Nhập chợ',
          'icon': Icons.shopping_basket,
          'color': Colors.purple
        };
      default:
        return {'label': 'Khác', 'icon': Icons.receipt, 'color': Colors.grey};
    }
  }
}
