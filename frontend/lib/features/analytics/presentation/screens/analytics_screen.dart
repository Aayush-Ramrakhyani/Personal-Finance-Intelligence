import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/analytics_provider.dart';
import '../../data/analytics_models.dart';
import '../widgets/donut_chart.dart';
import '../widgets/trend_chart.dart';
import '../../../../shared/widgets/period_selector.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      final s = amount.toStringAsFixed(0);
      final len = s.length;
      if (len <= 3) return '₹$s';
      return '₹${s.substring(0, len - 3)},${s.substring(len - 3)}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Analytics',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              ref.invalidate(overviewProvider);
              ref.invalidate(categoryBreakdownProvider);
              ref.invalidate(cashFlowProvider);
              ref.invalidate(trendsProvider);
              ref.invalidate(monthComparisonProvider);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Period selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: PeriodSelector(
                selected: selectedPeriod,
                onChanged: (p) =>
                    ref.read(selectedPeriodProvider.notifier).state = p,
              ),
            ),
          ),

          // Overview stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: ref.watch(overviewProvider).when(
                    loading: () => const _LoadingCard(height: 100),
                    error: (e, _) => _ErrorCard(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(overviewProvider),
                    ),
                    data: (overview) =>
                        _OverviewCard(overview: overview, formatAmount: _formatAmount),
                  ),
            ),
          ),

          // Category donut chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SectionCard(
                title: 'Spending by Category',
                child: ref.watch(categoryBreakdownProvider).when(
                      loading: () => const _LoadingCard(height: 300),
                      error: (e, _) => _ErrorCard(
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(categoryBreakdownProvider),
                      ),
                      data: (categories) => DonutChart(
                        categories: categories,
                        formatAmount: _formatAmount,
                      ),
                    ),
              ),
            ),
          ),

          // Income vs Expense trend
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SectionCard(
                title: 'Income vs Expense Trend',
                child: ref.watch(cashFlowProvider).when(
                      loading: () => const _LoadingCard(height: 220),
                      error: (e, _) => _ErrorCard(
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(cashFlowProvider),
                      ),
                      data: (cashFlow) => TrendChart(
                        cashFlow: cashFlow,
                        formatAmount: _formatAmount,
                      ),
                    ),
              ),
            ),
          ),

          // Category bar chart
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SectionCard(
                title: 'Category Spending',
                child: ref.watch(categoryBreakdownProvider).when(
                      loading: () =>
                          const _LoadingCard(height: 200),
                      error: (e, _) => _ErrorCard(
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(categoryBreakdownProvider),
                      ),
                      data: (categories) => _CategoryBarChart(
                        categories: categories.take(6).toList(),
                        formatAmount: _formatAmount,
                      ),
                    ),
              ),
            ),
          ),

          // Month-over-month table
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _SectionCard(
                title: 'Month-over-Month',
                child: ref.watch(monthComparisonProvider).when(
                      loading: () =>
                          const _LoadingCard(height: 150),
                      error: (e, _) => _ErrorCard(
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(monthComparisonProvider),
                      ),
                      data: (months) => _MonthTable(
                        months: months,
                        formatAmount: _formatAmount,
                      ),
                    ),
              ),
            ),
          ),

          // Anomalies
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ref.watch(trendsProvider).when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (trends) => trends.anomalies.isEmpty
                        ? const SizedBox.shrink()
                        : _SectionCard(
                            title: 'Unusual Spending',
                            child: _AnomaliesList(
                              anomalies: trends.anomalies,
                              formatAmount: _formatAmount,
                            ),
                          ),
                  ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview card
// ---------------------------------------------------------------------------
class _OverviewCard extends StatelessWidget {
  final OverviewModel overview;
  final String Function(double) formatAmount;

  const _OverviewCard({required this.overview, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F36), Color(0xFF252B45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Income',
              value: formatAmount(overview.totalIncome),
              color: const Color(0xFF00C896),
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
              width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _StatColumn(
              label: 'Expense',
              value: formatAmount(overview.totalExpense),
              color: const Color(0xFFFF5252),
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
              width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _StatColumn(
              label: 'Savings',
              value: formatAmount(overview.netSavings),
              color: overview.netSavings >= 0
                  ? const Color(0xFF00C896)
                  : const Color(0xFFFF5252),
              icon: Icons.savings_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category bar chart
// ---------------------------------------------------------------------------
class _CategoryBarChart extends StatelessWidget {
  final List<CategoryAnalyticsModel> categories;
  final String Function(double) formatAmount;

  const _CategoryBarChart({
    required this.categories,
    required this.formatAmount,
  });

  static const List<Color> _colors = [
    Color(0xFF00C896),
    Color(0xFF40C4FF),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
          child: Text('No data', style: TextStyle(color: Colors.white54)));
    }
    final maxAmt =
        categories.fold(0.0, (a, c) => a > c.amount ? a : c.amount);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmt * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF252B45),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${categories[groupIndex].category}\n${formatAmount(rod.toY)}',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= categories.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      categories[index].category.length > 6
                          ? '${categories[index].category.substring(0, 5)}.'
                          : categories[index].category,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups:
              categories.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.amount,
                  color: _colors[entry.key % _colors.length],
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month table
// ---------------------------------------------------------------------------
class _MonthTable extends StatelessWidget {
  final List<MonthComparisonModel> months;
  final String Function(double) formatAmount;

  const _MonthTable({required this.months, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1)),
            ),
          ),
          children: ['Month', 'Income', 'Expense', 'Savings']
              .map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      h,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
        ),
        ...months.map((m) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    m.monthLabel.substring(0, 3),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    formatAmount(m.income),
                    style: const TextStyle(
                        color: Color(0xFF00C896), fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    formatAmount(m.expense),
                    style: const TextStyle(
                        color: Color(0xFFFF5252), fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    formatAmount(m.savings),
                    style: TextStyle(
                        color: m.savings >= 0
                            ? const Color(0xFF00C896)
                            : const Color(0xFFFF5252),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Anomalies list
// ---------------------------------------------------------------------------
class _AnomaliesList extends StatelessWidget {
  final List<AnomalyModel> anomalies;
  final String Function(double) formatAmount;

  const _AnomaliesList({
    required this.anomalies,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: anomalies.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9100).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFF9100).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFFF9100),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        a.description,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(a.amount),
                      style: const TextStyle(
                        color: Color(0xFFFF9100),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '+${a.deviationPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card wrapper
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C896),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5252), size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF00C896), size: 16),
            label: const Text('Retry',
                style: TextStyle(color: Color(0xFF00C896))),
          ),
        ],
      ),
    );
  }
}
