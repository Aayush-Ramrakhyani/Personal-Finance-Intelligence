import 'package:flutter/material.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/features/dashboard/data/dashboard_models.dart';
import 'package:personal_finance_intelligence/shared/widgets/finance_card.dart';

class BudgetProgressCard extends StatelessWidget {
  final List<BudgetAlert> alerts;

  const BudgetProgressCard({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return FinanceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Budget Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alerts.length} active',
                  style: const TextStyle(
                      color: AppTheme.warningColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BudgetItem(alert: a),
              )),
        ],
      ),
    );
  }
}

class _BudgetItem extends StatelessWidget {
  final BudgetAlert alert;

  const _BudgetItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final pct = (alert.percentage / 100).clamp(0.0, 1.0);
    final color = alert.isOverBudget
        ? AppTheme.errorColor
        : alert.isWarning
            ? AppTheme.warningColor
            : AppTheme.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(alert.categoryName,
                  style: const TextStyle(fontSize: 13)),
            ),
            Text(
              '${alert.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              CurrencyFormatter.formatCompact(alert.spent),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
            const Text(' / ',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            Text(
              CurrencyFormatter.formatCompact(alert.limit),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
