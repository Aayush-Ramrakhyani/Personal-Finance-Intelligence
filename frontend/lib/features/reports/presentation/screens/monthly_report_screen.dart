import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/report_provider.dart';
import '../../data/report_models.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

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
    final period = ref.watch(selectedReportPeriodProvider);
    final reportAsync = ref.watch(monthlyReportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Monthly Report',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white70),
            onPressed: () => _showDownloadInfo(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            onPressed: () => _showShareInfo(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Month picker
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _MonthPicker(
                period: period,
                onChanged: (p) =>
                    ref.read(selectedReportPeriodProvider.notifier).state = p,
              ),
            ),
          ),

          // Report content
          SliverToBoxAdapter(
            child: reportAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00C896)),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(monthlyReportProvider),
                ),
              ),
              data: (report) => _ReportBody(
                report: report,
                formatAmount: _formatAmount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download feature coming soon'),
        backgroundColor: Color(0xFF1A1F36),
      ),
    );
  }

  void _showShareInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        backgroundColor: Color(0xFF1A1F36),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month picker
// ---------------------------------------------------------------------------
class _MonthPicker extends StatelessWidget {
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onChanged;

  const _MonthPicker({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final date = DateTime(period.year, period.month);
    final now = DateTime.now();
    final canGoNext =
        DateTime(period.year, period.month + 1).isBefore(DateTime(now.year, now.month + 1));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white70),
            onPressed: () {
              final prev = DateTime(period.year, period.month - 1);
              onChanged(ReportPeriod(year: prev.year, month: prev.month));
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: canGoNext ? Colors.white70 : Colors.white24,
            ),
            onPressed: canGoNext
                ? () {
                    final next =
                        DateTime(period.year, period.month + 1);
                    onChanged(
                        ReportPeriod(year: next.year, month: next.month));
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report body
// ---------------------------------------------------------------------------
class _ReportBody extends StatelessWidget {
  final MonthlyReportModel report;
  final String Function(double) formatAmount;

  const _ReportBody({required this.report, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI narrative
          if (report.aiNarrative.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C896), Color(0xFF40C4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.aiNarrative,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Income / Expense / Savings summary
          _ReportSection(
            title: 'Summary',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Total Income',
                  value: formatAmount(report.totalIncome),
                  color: const Color(0xFF00C896),
                ),
                _SummaryRow(
                  label: 'Total Expense',
                  value: formatAmount(report.totalExpense),
                  color: const Color(0xFFFF5252),
                ),
                const Divider(color: Colors.white12),
                _SummaryRow(
                  label: 'Net Savings',
                  value: formatAmount(report.netSavings),
                  color: report.netSavings >= 0
                      ? const Color(0xFF00C896)
                      : const Color(0xFFFF5252),
                  isBold: true,
                ),
                _SummaryRow(
                  label: 'Savings Rate',
                  value:
                      '${report.savingsRate.toStringAsFixed(1)}%',
                  color: Colors.white70,
                ),
              ],
            ),
          ),

          // Category breakdown
          if (report.categoryBreakdown.isNotEmpty) ...[
            _ReportSection(
              title: 'Category Breakdown',
              child: Column(
                children: report.categoryBreakdown.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cat.category,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              formatAmount(cat.amount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cat.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cat.percentage / 100,
                            backgroundColor:
                                Colors.white.withOpacity(0.08),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00C896)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Budget performance
          if (report.budgetPerformance.isNotEmpty) ...[
            _ReportSection(
              title: 'Budget Performance',
              child: Column(
                children: report.budgetPerformance.map((bp) {
                  final color = bp.percentageUsed < 75
                      ? const Color(0xFF00C896)
                      : bp.percentageUsed < 90
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFFF5252);
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
                            bp.category,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${formatAmount(bp.spent)} / ${formatAmount(bp.budgeted)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bp.percentageUsed.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Previous month comparison
          if (report.comparisonWithPrevious != null) ...[
            _ReportSection(
              title: 'vs ${report.comparisonWithPrevious!.previousMonthLabel}',
              child: _ComparisonWidget(
                comparison: report.comparisonWithPrevious!,
                formatAmount: formatAmount,
              ),
            ),
          ],

          // Notable transactions
          if (report.notableTransactions.isNotEmpty) ...[
            _ReportSection(
              title: 'Notable Transactions',
              child: Column(
                children: report.notableTransactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${DateFormat('MMM dd').format(tx.date)} • ${tx.category}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                              if (tx.reason.isNotEmpty)
                                Text(
                                  tx.reason,
                                  style: const TextStyle(
                                      color: Color(0xFFFFC107),
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatAmount(tx.amount),
                          style: TextStyle(
                            color: tx.isExpense
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF00C896),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Recurring expenses
          if (report.recurringExpenses.isNotEmpty) ...[
            _ReportSection(
              title: 'Recurring Expenses',
              child: Column(
                children: report.recurringExpenses.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded,
                            color: Color(0xFF40C4FF), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.merchantName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        Text(
                          r.frequency.capitalize(),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatAmount(r.amount),
                          style: const TextStyle(
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Anomalies
          if (report.anomalies.isNotEmpty) ...[
            _ReportSection(
              title: 'Unusual Spending',
              child: Column(
                children: report.anomalies.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFF9100).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF9100)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFFFF9100),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                      color: Colors.white54,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${a.deviationPercent.toStringAsFixed(0)}% vs usual',
                            style: const TextStyle(
                              color: Color(0xFFFF9100),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comparison widget
// ---------------------------------------------------------------------------
class _ComparisonWidget extends StatelessWidget {
  final MonthComparisonReportModel comparison;
  final String Function(double) formatAmount;

  const _ComparisonWidget(
      {required this.comparison, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ComparisonRow(
          label: 'Income',
          diff: comparison.incomeDiff,
          percent: comparison.incomeChangePercent,
          formatAmount: formatAmount,
          positiveIsGood: true,
        ),
        _ComparisonRow(
          label: 'Expense',
          diff: comparison.expenseDiff,
          percent: comparison.expenseChangePercent,
          formatAmount: formatAmount,
          positiveIsGood: false,
        ),
        _ComparisonRow(
          label: 'Savings',
          diff: comparison.savingsDiff,
          percent: comparison.savingsDiff != 0
              ? (comparison.savingsDiff.abs() /
                  (comparison.savingsDiff > 0
                      ? comparison.savingsDiff
                      : -comparison.savingsDiff)) *
                  100
              : 0,
          formatAmount: formatAmount,
          positiveIsGood: true,
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double diff;
  final double percent;
  final String Function(double) formatAmount;
  final bool positiveIsGood;

  const _ComparisonRow({
    required this.label,
    required this.diff,
    required this.percent,
    required this.formatAmount,
    required this.positiveIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = diff >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood
        ? const Color(0xFF00C896)
        : const Color(0xFFFF5252);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
            ),
          ),
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${formatAmount(diff.abs())} (${percent.abs().toStringAsFixed(1)}%)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isBold ? 14 : 13,
              fontWeight:
                  isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5252), size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
