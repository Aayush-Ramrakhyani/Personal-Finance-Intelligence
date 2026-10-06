import 'package:equatable/equatable.dart';

class OverviewData extends Equatable {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final double savingsRate;
  final double netSavings;
  final int transactionCount;
  final String period;
  final List<BudgetAlert> budgetAlerts;

  const OverviewData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.savingsRate,
    required this.netSavings,
    required this.transactionCount,
    required this.period,
    required this.budgetAlerts,
  });

  factory OverviewData.fromJson(Map<String, dynamic> j) => OverviewData(
        totalBalance: (j['total_balance'] as num).toDouble(),
        totalIncome: (j['total_income'] as num).toDouble(),
        totalExpenses: (j['total_expenses'] as num).toDouble(),
        savingsRate: (j['savings_rate'] as num).toDouble(),
        netSavings: (j['net_savings'] as num).toDouble(),
        transactionCount: j['transaction_count'] as int,
        period: j['period'] as String,
        budgetAlerts: (j['budget_alerts'] as List<dynamic>? ?? [])
            .map((e) => BudgetAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        totalBalance, totalIncome, totalExpenses, savingsRate, netSavings,
        transactionCount, period, budgetAlerts,
      ];
}

class BudgetAlert extends Equatable {
  final String budgetId;
  final String categoryName;
  final double spent;
  final double limit;
  final double percentage;

  const BudgetAlert({
    required this.budgetId,
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.percentage,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> j) => BudgetAlert(
        budgetId: j['budget_id'] as String,
        categoryName: j['category_name'] as String,
        spent: (j['spent'] as num).toDouble(),
        limit: (j['limit'] as num).toDouble(),
        percentage: (j['percentage'] as num).toDouble(),
      );

  bool get isOverBudget => percentage >= 100;
  bool get isWarning => percentage >= 80;

  @override
  List<Object?> get props => [budgetId, categoryName, spent, limit, percentage];
}

class CashFlowMonth extends Equatable {
  final int year;
  final int month;
  final String monthLabel;
  final double income;
  final double expenses;
  final double net;

  const CashFlowMonth({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.income,
    required this.expenses,
    required this.net,
  });

  factory CashFlowMonth.fromJson(Map<String, dynamic> j) => CashFlowMonth(
        year: j['year'] as int,
        month: j['month'] as int,
        monthLabel: j['month_label'] as String,
        income: (j['income'] as num).toDouble(),
        expenses: (j['expenses'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [year, month, income, expenses, net];
}
