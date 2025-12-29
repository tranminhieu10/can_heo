import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../domain/entities/cage.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_cage_repository.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import '../../../../injection_container.dart';

// ==================== THEME CONSTANTS ====================
class _DashboardTheme {
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
  );

  static const warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  );

  static const infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration cardDecorationHover = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 30,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  int _refreshKey = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refresh() {
    _animationController.reset();
    setState(() {
      _refreshKey++;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(onRefresh: _refresh),
                const SizedBox(height: 24),
                _TodayStatsSection(key: ValueKey('stats_$_refreshKey')),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _DetailedBarnInventorySection(
                          key: ValueKey('barn_detailed_$_refreshKey')),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _ReturnedFromMarketSection(
                          key: ValueKey('returned_market_$_refreshKey')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _MarketSummaryStatsSection(
                    key: ValueKey('market_summary_$_refreshKey')),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _WeeklyChartSection(
                              key: ValueKey('chart_$_refreshKey')),
                          const SizedBox(height: 24),
                          _RecentTransactionsSection(
                              key: ValueKey('transactions_$_refreshKey')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _TopPartnersSection(
                              key: ValueKey('partners_$_refreshKey')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
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
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _DashboardTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng quan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(now),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Live clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeFormat.format(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _AnimatedActionButton(
            icon: Icons.refresh_rounded,
            label: 'Làm mới',
            onTap: onRefresh,
          ),
          const SizedBox(width: 12),
          _AnimatedActionButton(
            icon: Icons.file_download_outlined,
            label: 'Xuất báo cáo',
            onTap: () {},
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AnimatedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? Colors.white
                : Colors.white.withOpacity(_isHovered ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color:
                    widget.isPrimary ? const Color(0xFF667eea) : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color:
                      widget.isPrimary ? const Color(0xFF667eea) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
          return Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 16 : 0),
                  child: const _ShimmerCard(),
                ),
              ),
            ),
          );
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
              child: _ModernStatCard(
                title: 'Doanh thu',
                value: _formatCurrency(totalRevenue),
                icon: Icons.trending_up_rounded,
                gradient: _DashboardTheme.successGradient,
                trend: _calculateTrend(totalRevenue, yesterdayRevenue),
                trendValue: totalRevenue - yesterdayRevenue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Chi phí',
                value: _formatCurrency(totalCost),
                icon: Icons.account_balance_wallet_rounded,
                gradient: _DashboardTheme.warningGradient,
                trend: _calculateTrend(totalCost, yesterdayCost),
                trendValue: totalCost - yesterdayCost,
                invertTrend: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Lợi nhuận',
                value: _formatCurrency(totalProfit),
                icon: Icons.savings_rounded,
                gradient: totalProfit >= 0
                    ? _DashboardTheme.infoGradient
                    : const LinearGradient(
                        colors: [Color(0xFFeb3349), Color(0xFFf45c43)]),
                trend: _calculateTrend(totalProfit, yesterdayProfit),
                trendValue: totalProfit - yesterdayProfit,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                title: 'Số con đã bán',
                value: NumberFormat('#,###').format(totalPigs),
                subtitle: 'con',
                icon: Icons.pets_rounded,
                gradient: _DashboardTheme.primaryGradient,
                trend: totalPigs > yesterdayPigs
                    ? '+${totalPigs - yesterdayPigs}'
                    : '${totalPigs - yesterdayPigs}',
                trendValue: (totalPigs - yesterdayPigs).toDouble(),
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

// Shimmer loading effect
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard({super.key});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModernStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final String trend;
  final double trendValue;
  final bool isInteger;
  final bool invertTrend;

  const _ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    required this.trend,
    required this.trendValue,
    this.isInteger = false,
    this.invertTrend = false,
  });

  @override
  State<_ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<_ModernStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPositive =
        widget.invertTrend ? widget.trendValue <= 0 : widget.trendValue >= 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: _isHovered
            ? _DashboardTheme.cardDecorationHover
            : _DashboardTheme.cardDecoration,
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.gradient as LinearGradient)
                            .colors
                            .first
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                _TrendBadge(
                  trend: widget.trend,
                  isPositive: isPositive,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    widget.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool isPositive;

  const _TrendBadge({
    super.key,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color:
                isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
class _WeeklyChartSection extends StatefulWidget {
  const _WeeklyChartSection({super.key});

  @override
  State<_WeeklyChartSection> createState() => _WeeklyChartSectionState();
}

class _WeeklyChartSectionState extends State<_WeeklyChartSection> {
  String _selectedPeriod = '7 ngày';
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4facfe).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: Color(0xFF4facfe),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Biểu đồ doanh thu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              _PeriodSelector(
                selected: _selectedPeriod,
                onChanged: (value) => setState(() => _selectedPeriod = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: StreamBuilder<List<InvoiceEntity>>(
              stream: invoiceRepo.watchInvoices(type: 2),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF4facfe)),
                    ),
                  );
                }

                final invoices = snapshot.data!;
                final now = DateTime.now();
                final days = _selectedPeriod == '7 ngày'
                    ? 7
                    : _selectedPeriod == '30 ngày'
                        ? 30
                        : 90;
                final List<double> dailyRevenue =
                    List.filled(days > 14 ? 14 : days, 0.0);
                final List<String> dayLabels = [];
                final step = days > 14 ? (days / 14).ceil() : 1;

                for (int i = (days > 14 ? 13 : days - 1); i >= 0; i--) {
                  final dayOffset = i * step;
                  final targetDate = now.subtract(Duration(days: dayOffset));

                  double periodTotal = 0;
                  for (int d = 0; d < step; d++) {
                    final checkDate =
                        now.subtract(Duration(days: dayOffset + d));
                    final startOfDay = DateTime(
                        checkDate.year, checkDate.month, checkDate.day);
                    final endOfDay = startOfDay.add(const Duration(days: 1));

                    for (final inv in invoices) {
                      if (inv.createdDate.isAfter(startOfDay) &&
                          inv.createdDate.isBefore(endOfDay)) {
                        periodTotal += inv.finalAmount;
                      }
                    }
                  }

                  dailyRevenue[(days > 14 ? 13 : days - 1) - i] = periodTotal;
                  if (days <= 7) {
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
                  } else {
                    dayLabels.add('${targetDate.day}/${targetDate.month}');
                  }
                }

                return _ModernBarChart(
                  data: dailyRevenue,
                  labels: dayLabels,
                  hoveredIndex: _hoveredIndex,
                  onHover: (index) => setState(() => _hoveredIndex = index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['7 ngày', '30 ngày', '90 ngày'].map((period) {
          final isSelected = selected == period;
          return GestureDetector(
            onTap: () => onChanged(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                period,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFF4facfe) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModernBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final int? hoveredIndex;
  final ValueChanged<int?> onHover;

  const _ModernBarChart({
    super.key,
    required this.data,
    required this.labels,
    this.hoveredIndex,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return _EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Chưa có dữ liệu',
        subtitle: 'Doanh thu sẽ hiển thị khi có giao dịch',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            (constraints.maxWidth - (data.length - 1) * 8) / data.length;
        final effectiveBarWidth = barWidth.clamp(24.0, 48.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(data.length, (index) {
            final value = data[index];
            final height = maxValue > 0 ? (value / maxValue) * 180 : 0.0;
            final isHovered = hoveredIndex == index;

            return MouseRegion(
              onEnter: (_) => onHover(index),
              onExit: (_) => onHover(null),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isHovered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatValue(value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 28),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: effectiveBarWidth,
                    height: (height.clamp(4.0, 180.0)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isHovered
                            ? [const Color(0xFF4facfe), const Color(0xFF00f2fe)]
                            : [
                                const Color(0xFF4facfe).withOpacity(0.7),
                                const Color(0xFF00f2fe).withOpacity(0.7)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4facfe).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isHovered
                          ? const Color(0xFF4facfe)
                          : Colors.grey[500],
                      fontWeight:
                          isHovered ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else if (value == 0) {
      return '0';
    }
    return value.toStringAsFixed(0);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
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

// ==================== DETAILED BARN INVENTORY ====================
class _DetailedBarnInventorySection extends StatelessWidget {
  const _DetailedBarnInventorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê kho chi tiết',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest2(
              invoiceRepo.watchInvoices(type: 0),
              invoiceRepo.watchInvoices(type: 1),
              (a, b) => [a, b],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final importBarn = snapshot.data![0];
              final exportBarn = snapshot.data![1];

              // Map: pigType -> cage -> quantity
              Map<String, Map<String, int>> detailedInventory = {};

              // Process imports
              for (final inv in importBarn) {
                String cage = '';
                final noteLines = (inv.note ?? '').split('|');
                for (final line in noteLines) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('Chuồng:')) {
                    cage = trimmed.substring(7).trim();
                    break;
                  }
                }
                if (cage.isEmpty) cage = 'Không rõ';

                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';

                  if (!detailedInventory.containsKey(pigType)) {
                    detailedInventory[pigType] = {};
                  }

                  detailedInventory[pigType]![cage] =
                      (detailedInventory[pigType]![cage] ?? 0) +
                          detail.quantity;
                }
              }

              // Process exports
              for (final inv in exportBarn) {
                String cage = '';
                final noteLines = (inv.note ?? '').split('|');
                for (final line in noteLines) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('Chuồng:')) {
                    cage = trimmed.substring(7).trim();
                    break;
                  }
                }
                if (cage.isEmpty) cage = 'Không rõ';

                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';

                  if (!detailedInventory.containsKey(pigType)) {
                    detailedInventory[pigType] = {};
                  }

                  detailedInventory[pigType]![cage] =
                      (detailedInventory[pigType]![cage] ?? 0) -
                          detail.quantity;
                }
              }

              if (detailedInventory.isEmpty) {
                return _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chưa có dữ liệu tồn kho',
                  subtitle: 'Dữ liệu sẽ hiển thị khi có nhập/xuất kho',
                );
              }

              return _ModernDataTable(
                columns: const ['Loại heo', 'Chuồng', 'Số lượng'],
                rows: _buildDetailedRows(detailedInventory),
                headerColor: const Color(0xFF3B82F6),
              );
            },
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildDetailedRows(
      Map<String, Map<String, int>> inventory) {
    List<List<Widget>> rows = [];

    inventory.forEach((pigType, cages) {
      cages.forEach((cage, quantity) {
        if (quantity > 0) {
          final color = quantity > 50
              ? const Color(0xFF10B981)
              : quantity > 20
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);

          rows.add([
            Text(pigType, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(cage, style: TextStyle(color: Colors.grey[600])),
            _QuantityBadge(quantity: quantity, color: color),
          ]);
        }
      });
    });

    return rows;
  }
}

class _ModernDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final Color headerColor;

  const _ModernDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 20,
            headingRowHeight: 48,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingRowColor:
                WidgetStateProperty.all(headerColor.withOpacity(0.08)),
            columns: columns
                .map((col) => DataColumn(
                      label: Text(
                        col,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: headerColor,
                        ),
                      ),
                    ))
                .toList(),
            rows: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final cells = entry.value;
              return DataRow(
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.grey.shade50;
                  }
                  return index.isEven ? Colors.white : const Color(0xFFFAFAFA);
                }),
                cells: cells.map((widget) => DataCell(widget)).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final int quantity;
  final Color color;

  const _QuantityBadge({
    super.key,
    required this.quantity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$quantity con',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ==================== DETAILED MARKET STATS ====================
class _DetailedMarketStatsSection extends StatelessWidget {
  const _DetailedMarketStatsSection({super.key});

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
            '🛒 Thống kê chợ chi tiết',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest4(
              invoiceRepo.watchInvoices(
                  type: 0), // Nhập kho (heo thừa từ chợ về)
              invoiceRepo.watchInvoices(type: 1), // Xuất kho (từ kho ra chợ)
              invoiceRepo.watchInvoices(type: 2), // Xuất chợ (bán)
              invoiceRepo.watchInvoices(type: 3), // Nhập chợ từ NCC
              (a, b, c, d) => [a, b, c, d],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final importBarn = snapshot.data![0]; // Nhập kho (Type 0)
              final exportBarn = snapshot.data![1]; // Xuất kho (Type 1)
              final exportMarket = snapshot.data![2]; // Xuất chợ (Type 2)
              final importMarket = snapshot.data![3]; // Nhập chợ (Type 3)

              // Calculate stats by pig type
              Map<String, Map<String, dynamic>> marketStats = {};

              // Helper to initialize pigType entry
              void ensurePigType(String pigType) {
                if (!marketStats.containsKey(pigType)) {
                  marketStats[pigType] = {
                    'imported': 0, // Nhập từ NCC (Type 3)
                    'exportedFromBarn': 0, // Xuất từ kho ra chợ (Type 1)
                    'sold': 0, // Đã bán (Type 2)
                    'returnedToBarnTotal': 0, // Tổng nhập về kho (Type 0)
                    'remaining':
                        0, // Còn lại = imported + exportedFromBarn - sold - returnedToBarnTotal
                    'returnedToBarn':
                        <String, int>{}, // Chi tiết nhập về kho theo chuồng
                  };
                }
              }

              // Process market imports from supplier (type 3)
              for (final inv in importMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['imported'] =
                      (marketStats[pigType]!['imported'] as int) +
                          detail.quantity;
                }
              }

              // Process barn exports to market (type 1)
              for (final inv in exportBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['exportedFromBarn'] =
                      (marketStats[pigType]!['exportedFromBarn'] as int) +
                          detail.quantity;
                }
              }

              // Process market exports (sold at market - type 2)
              for (final inv in exportMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['sold'] =
                      (marketStats[pigType]!['sold'] as int) + detail.quantity;
                }
              }

              // Process barn imports (unsold pigs returned from market - type 0)
              for (final inv in importBarn) {
                String cage = '';
                final note = inv.note ?? '';
                final noteLines = note.split('|');
                for (final line in noteLines) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('Chuồng:')) {
                    cage = trimmed.substring(7).trim();
                    break;
                  }
                }
                if (cage.isEmpty) cage = 'Không rõ';

                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);

                  // Add to total returned to barn
                  marketStats[pigType]!['returnedToBarnTotal'] =
                      (marketStats[pigType]!['returnedToBarnTotal'] as int) +
                          detail.quantity;

                  // Add to detail by cage
                  final returnedMap = marketStats[pigType]!['returnedToBarn']
                      as Map<String, int>;
                  returnedMap[cage] =
                      (returnedMap[cage] ?? 0) + detail.quantity;
                }
              }

              // Calculate remaining = imported + exportedFromBarn - sold - returnedToBarnTotal
              // Tồn chợ = Nhập chợ (Type 3) + Xuất kho (Type 1) - Xuất chợ (Type 2) - Nhập kho (Type 0)
              marketStats.forEach((pigType, data) {
                final imported = data['imported'] as int;
                final exportedFromBarn = data['exportedFromBarn'] as int;
                final sold = data['sold'] as int;
                final returnedToBarnTotal = data['returnedToBarnTotal'] as int;
                final remaining =
                    imported + exportedFromBarn - sold - returnedToBarnTotal;
                data['remaining'] =
                    remaining < 0 ? 0 : remaining; // Không cho phép số âm
              });

              if (marketStats.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có dữ liệu chợ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: [
                  // Summary section
                  Row(
                    children: [
                      Expanded(
                        child: _MarketStatCard(
                          title: 'Đã bán',
                          icon: Icons.sell,
                          color: Colors.green,
                          stats: marketStats,
                          type: 'sold',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MarketStatCard(
                          title: 'Còn lại tại chợ',
                          icon: Icons.shopping_cart,
                          color: Colors.blue,
                          stats: marketStats,
                          type: 'remaining',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==================== RETURNED FROM MARKET SECTION ====================
class _ReturnedFromMarketSection extends StatelessWidget {
  const _ReturnedFromMarketSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();
    final cageRepo = sl<ICageRepository>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chi tiết nhập về kho từ chợ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<dynamic>>(
            stream: Rx.combineLatest2(
              invoiceRepo.watchInvoices(type: 0),
              cageRepo.watchAllCages(),
              (invoices, cages) => [invoices, cages],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final importBarn = snapshot.data![0] as List<InvoiceEntity>;
              final cages = snapshot.data![1] as List<CageEntity>;

              // Tạo map cageId -> cageName
              final cageNames = <String, String>{};
              for (final cage in cages) {
                cageNames[cage.id] = cage.name;
              }

              Map<String, Map<String, int>> returnedFromMarket = {};

              // Process tất cả phiếu nhập kho (Type 0) - đều là hàng từ chợ về
              for (final inv in importBarn) {
                // Lấy tên chuồng từ cageId
                String cageName = 'Không rõ';

                if (inv.cageId != null && inv.cageId!.isNotEmpty) {
                  cageName = cageNames[inv.cageId!] ?? inv.cageId!;
                } else {
                  // Fallback: lấy từ note
                  final note = inv.note ?? '';
                  final noteLines = note.split('|');
                  for (final line in noteLines) {
                    final trimmed = line.trim();
                    if (trimmed.startsWith('Chuồng:')) {
                      cageName = trimmed.substring(7).trim();
                      break;
                    }
                  }
                }

                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';

                  if (!returnedFromMarket.containsKey(pigType)) {
                    returnedFromMarket[pigType] = {};
                  }

                  returnedFromMarket[pigType]![cageName] =
                      (returnedFromMarket[pigType]![cageName] ?? 0) +
                          detail.quantity;
                }
              }

              if (returnedFromMarket.isEmpty) {
                return _EmptyState(
                  icon: Icons.sync_alt_outlined,
                  title: 'Chưa có dữ liệu nhập về',
                  subtitle: 'Dữ liệu sẽ hiển thị khi có hàng từ chợ về kho',
                );
              }

              return _ModernDataTable(
                columns: const ['Loại heo', 'Chuồng', 'Số lượng'],
                rows: _buildReturnedRows(returnedFromMarket),
                headerColor: const Color(0xFF8B5CF6),
              );
            },
          ),
        ],
      ),
    );
  }

  List<List<Widget>> _buildReturnedRows(
      Map<String, Map<String, int>> inventory) {
    List<List<Widget>> rows = [];

    inventory.forEach((pigType, cages) {
      cages.forEach((cage, quantity) {
        if (quantity > 0) {
          rows.add([
            Text(pigType, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(cage, style: TextStyle(color: Colors.grey[600])),
            _QuantityBadge(quantity: quantity, color: const Color(0xFF8B5CF6)),
          ]);
        }
      });
    });

    return rows;
  }
}

// ==================== MARKET SUMMARY STATS ====================
class _MarketSummaryStatsSection extends StatelessWidget {
  const _MarketSummaryStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceRepo = sl<IInvoiceRepository>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê chợ tóm tắt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<List<InvoiceEntity>>>(
            stream: Rx.combineLatest4(
              invoiceRepo.watchInvoices(type: 0), // Nhập kho
              invoiceRepo.watchInvoices(type: 1), // Xuất kho
              invoiceRepo.watchInvoices(type: 2), // Xuất chợ
              invoiceRepo.watchInvoices(type: 3), // Nhập chợ
              (a, b, c, d) => [a, b, c, d],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final importBarn = snapshot.data![0]; // Type 0
              final exportBarn = snapshot.data![1]; // Type 1
              final exportMarket = snapshot.data![2]; // Type 2
              final importMarket = snapshot.data![3]; // Type 3

              Map<String, Map<String, dynamic>> marketStats = {};

              // Helper function để khởi tạo entry
              void ensurePigType(String pigType) {
                if (!marketStats.containsKey(pigType)) {
                  marketStats[pigType] = {
                    'imported': 0,
                    'exportedFromBarn': 0,
                    'sold': 0,
                    'remaining': 0,
                    'returnedToBarn': 0,
                  };
                }
              }

              // + Nhập chợ (Type 3)
              for (final inv in importMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['imported'] =
                      (marketStats[pigType]!['imported'] as int) +
                          detail.quantity;
                }
              }

              // + Xuất kho (Type 1)
              for (final inv in exportBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['exportedFromBarn'] =
                      (marketStats[pigType]!['exportedFromBarn'] as int) +
                          detail.quantity;
                }
              }

              // - Xuất chợ (Type 2)
              for (final inv in exportMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['sold'] =
                      (marketStats[pigType]!['sold'] as int) + detail.quantity;
                }
              }

              // - Nhập kho (Type 0)
              for (final inv in importBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  ensurePigType(pigType);
                  marketStats[pigType]!['returnedToBarn'] =
                      (marketStats[pigType]!['returnedToBarn'] as int) +
                          detail.quantity;
                }
              }

              // Tồn chợ = Nhập chợ + Xuất kho - Xuất chợ - Nhập kho
              marketStats.forEach((pigType, data) {
                final imported = data['imported'] as int;
                final exportedFromBarn = data['exportedFromBarn'] as int;
                final sold = data['sold'] as int;
                final returnedToBarn = data['returnedToBarn'] as int;
                final remaining =
                    imported + exportedFromBarn - sold - returnedToBarn;
                data['remaining'] = remaining < 0 ? 0 : remaining;
              });

              if (marketStats.isEmpty) {
                return _EmptyState(
                  icon: Icons.store_outlined,
                  title: 'Chưa có dữ liệu chợ',
                  subtitle: 'Dữ liệu sẽ hiển thị khi có giao dịch tại chợ',
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _ModernMarketStatCard(
                      title: 'Đã bán',
                      icon: Icons.sell_rounded,
                      gradient: _DashboardTheme.successGradient,
                      stats: marketStats,
                      type: 'sold',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _ModernMarketStatCard(
                      title: 'Còn lại tại chợ',
                      icon: Icons.shopping_cart_rounded,
                      gradient: _DashboardTheme.infoGradient,
                      stats: marketStats,
                      type: 'remaining',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModernMarketStatCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Map<String, Map<String, dynamic>> stats;
  final String type;

  const _ModernMarketStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.stats,
    required this.type,
  });

  @override
  State<_ModernMarketStatCard> createState() => _ModernMarketStatCardState();
}

class _ModernMarketStatCardState extends State<_ModernMarketStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    int total = 0;
    widget.stats.forEach((pigType, data) {
      total += (data[widget.type] as int);
    });

    final gradientColors = (widget.gradient as LinearGradient).colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(_isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$total con',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: widget.stats.entries.where((entry) {
                  final qty = entry.value[widget.type] as int;
                  return qty > 0;
                }).map((entry) {
                  final qty = entry.value[widget.type] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, Map<String, dynamic>> stats;
  final String type;

  const _MarketStatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.stats,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    int total = 0;
    stats.forEach((pigType, data) {
      total += (data[type] as int);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$total con',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...stats.entries.map((entry) {
            final qty = entry.value[type] as int;
            if (qty > 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$qty',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
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
            '📦 Tồn kho (Chuồng)',
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
            // Tồn chợ = Nhập chợ (3) + Xuất kho (1) - Xuất chợ (2) - Nhập kho (0)
            stream: Rx.combineLatest4(
              invoiceRepo.watchInvoices(type: 3), // Nhập chợ từ NCC
              invoiceRepo.watchInvoices(type: 1), // Xuất kho ra chợ
              invoiceRepo.watchInvoices(type: 2), // Xuất chợ bán cho khách
              invoiceRepo.watchInvoices(type: 0), // Nhập kho (hàng thừa về kho)
              (a, b, c, d) => [a, b, c, d],
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final importMarket =
                  snapshot.data![0]; // Type 3: Nhập chợ từ NCC (+)
              final exportBarn =
                  snapshot.data![1]; // Type 1: Xuất kho ra chợ (+)
              final exportMarket =
                  snapshot.data![2]; // Type 2: Xuất chợ bán (-)
              final importBarn =
                  snapshot.data![3]; // Type 0: Nhập kho hàng thừa (-)

              Map<String, int> inventory = {};

              // + Nhập chợ từ NCC (Type 3)
              for (final inv in importMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) + detail.quantity;
                }
              }

              // + Xuất kho ra chợ (Type 1)
              for (final inv in exportBarn) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) + detail.quantity;
                }
              }

              // - Xuất chợ bán cho khách (Type 2)
              for (final inv in exportMarket) {
                for (final detail in inv.details) {
                  final pigType = detail.pigType ?? 'Không rõ';
                  inventory[pigType] =
                      (inventory[pigType] ?? 0) - detail.quantity;
                }
              }

              // - Nhập kho hàng thừa (Type 0)
              for (final inv in importBarn) {
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
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Top khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<InvoiceEntity>>(
            stream: invoiceRepo.watchInvoices(type: 2),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
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
                return _EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Chưa có khách hàng',
                  subtitle: 'Dữ liệu sẽ hiển thị khi có giao dịch',
                );
              }

              return Column(
                children: sortedPartners.take(5).map((entry) {
                  final rank = sortedPartners.indexOf(entry) + 1;
                  return _ModernPartnerItem(
                    rank: rank,
                    name: entry.key,
                    revenue: entry.value,
                    maxRevenue: sortedPartners.first.value,
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

class _ModernPartnerItem extends StatefulWidget {
  final int rank;
  final String name;
  final double revenue;
  final double maxRevenue;

  const _ModernPartnerItem({
    super.key,
    required this.rank,
    required this.name,
    required this.revenue,
    required this.maxRevenue,
  });

  @override
  State<_ModernPartnerItem> createState() => _ModernPartnerItemState();
}

class _ModernPartnerItemState extends State<_ModernPartnerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      const Color(0xFF94A3B8),
      const Color(0xFF94A3B8),
    ];

    final rankColor = rankColors[widget.rank - 1];
    final progressWidth = (widget.revenue / widget.maxRevenue);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _isHovered ? Border.all(color: Colors.grey.shade200) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: widget.rank <= 3
                        ? LinearGradient(
                            colors: [
                              rankColor,
                              rankColor.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: widget.rank > 3 ? Colors.grey.shade200 : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: widget.rank <= 3
                        ? [
                            BoxShadow(
                              color: rankColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: widget.rank <= 3
                        ? Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${widget.rank}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatter.format(widget.revenue),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressWidth,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(
                  widget.rank <= 3 ? rankColor : const Color(0xFF10B981),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      decoration: _DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Giao dịch gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Xem tất cả'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
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
                return _EmptyState(
                  icon: Icons.receipt_outlined,
                  title: 'Chưa có giao dịch',
                  subtitle: 'Các giao dịch mới sẽ hiển thị ở đây',
                );
              }

              return Column(
                children: allInvoices.take(8).map((invoice) {
                  return _ModernTransactionItem(invoice: invoice);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModernTransactionItem extends StatefulWidget {
  final InvoiceEntity invoice;

  const _ModernTransactionItem({super.key, required this.invoice});

  @override
  State<_ModernTransactionItem> createState() => _ModernTransactionItemState();
}

class _ModernTransactionItemState extends State<_ModernTransactionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM HH:mm');

    final typeInfo = _getTypeInfo(widget.invoice.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.grey.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _isHovered ? Border.all(color: Colors.grey.shade200) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: typeInfo['gradient'] as Gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (typeInfo['color'] as Color).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                typeInfo['icon'] as IconData,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (typeInfo['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeInfo['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typeInfo['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.invoice.partnerName ?? 'Không rõ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(widget.invoice.createdDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(widget.invoice.finalAmount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.invoice.totalQuantity} con',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(int type) {
    switch (type) {
      case 0:
        return {
          'label': 'Nhập kho',
          'icon': Icons.download_rounded,
          'color': const Color(0xFF3B82F6),
          'gradient': const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        };
      case 1:
        return {
          'label': 'Xuất kho',
          'icon': Icons.upload_rounded,
          'color': const Color(0xFFF59E0B),
          'gradient': const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          ),
        };
      case 2:
        return {
          'label': 'Xuất chợ',
          'icon': Icons.storefront_rounded,
          'color': const Color(0xFF10B981),
          'gradient': const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
          ),
        };
      case 3:
        return {
          'label': 'Nhập chợ',
          'icon': Icons.shopping_basket_rounded,
          'color': const Color(0xFF8B5CF6),
          'gradient': const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          ),
        };
      default:
        return {
          'label': 'Khác',
          'icon': Icons.receipt_rounded,
          'color': Colors.grey,
          'gradient': LinearGradient(
            colors: [Colors.grey, Colors.grey.shade400],
          ),
        };
    }
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
