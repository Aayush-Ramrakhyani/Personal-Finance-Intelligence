import 'package:flutter/material.dart';
import 'package:personal_finance_intelligence/core/theme/app_theme.dart';
import 'package:personal_finance_intelligence/core/utils/currency_formatter.dart';
import 'package:personal_finance_intelligence/features/dashboard/data/dashboard_models.dart';
import 'package:personal_finance_intelligence/shared/widgets/finance_card.dart';

class SummaryCard extends StatelessWidget {
  final OverviewData data;

  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Net balance hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF1E2845)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Balance',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(data.totalBalance),
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    data.savingsRate >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: data.savingsRate >= 20
                        ? AppTheme.incomeColor
                        : data.savingsRate >= 0
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.savingsRate.toStringAsFixed(1)}% savings rate this month',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FinanceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.incomeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_downward,
                              size: 14, color: AppTheme.incomeColor),
                        ),
                        const SizedBox(width: 8),
                        const Text('Income',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatCompact(data.totalIncome),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.incomeColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FinanceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_upward,
                              size: 14, color: AppTheme.expenseColor),
                        ),
                        const SizedBox(width: 8),
                        const Text('Expenses',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatCompact(data.totalExpenses),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.expenseColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
