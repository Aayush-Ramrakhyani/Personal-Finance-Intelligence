import 'package:flutter/material.dart';

class OverviewModel {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final int transactionCount;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const OverviewModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.transactionCount,
    this.periodStart,
    this.periodEnd,
  });

  factory OverviewModel.fromJson(Map<String, dynamic> json) {
    return OverviewModel(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      netSavings: (json['net_savings'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
    );
  }
}

class CategoryAnalyticsModel {
  final String category;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final int transactionCount;
  final double previousAmount;
  final double changePercent;

  const CategoryAnalyticsModel({
    required this.category,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.previousAmount,
    required this.changePercent,
  });

  factory CategoryAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return CategoryAnalyticsModel(
      category: json['category'] as String,
      categoryIcon: json['category_icon'] as String? ?? 'category',
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      previousAmount: (json['previous_amount'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isIncreased => changePercent > 0;

  Color get changeColor =>
      isIncreased ? const Color(0xFFFF5252) : const Color(0xFF00C896);
}

class CashFlowModel {
  final int year;
  final int month;
  final String monthLabel;
  final double income;
  final double expense;
  final double savings;

  const CashFlowModel({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.savings,
  });

  factory CashFlowModel.fromJson(Map<String, dynamic> json) {
    return CashFlowModel(
      year: json['year'] as int,
      month: json['month'] as int,
      monthLabel: json['month_label'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
    );
  }
}

class TrendsModel {
  final double incomeGrowth;
  final double expenseGrowth;
  final List<AnomalyModel> anomalies;
  final List<String> insights;

  const TrendsModel({
    required this.incomeGrowth,
    required this.expenseGrowth,
    required this.anomalies,
    required this.insights,
  });

  factory TrendsModel.fromJson(Map<String, dynamic> json) {
    return TrendsModel(
      incomeGrowth: (json['income_growth'] as num?)?.toDouble() ?? 0.0,
      expenseGrowth: (json['expense_growth'] as num?)?.toDouble() ?? 0.0,
      anomalies: (json['anomalies'] as List<dynamic>?)
              ?.map((e) => AnomalyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class AnomalyModel {
  final String category;
  final String description;
  final double amount;
  final double expectedAmount;
  final double deviationPercent;
  final DateTime date;

  const AnomalyModel({
    required this.category,
    required this.description,
    required this.amount,
    required this.expectedAmount,
    required this.deviationPercent,
    required this.date,
  });

  factory AnomalyModel.fromJson(Map<String, dynamic> json) {
    return AnomalyModel(
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      deviationPercent: (json['deviation_percent'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class MonthComparisonModel {
  final String monthLabel;
  final double income;
  final double expense;
  final double savings;
  final double incomeChange;
  final double expenseChange;

  const MonthComparisonModel({
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.savings,
    required this.incomeChange,
    required this.expenseChange,
  });

  factory MonthComparisonModel.fromJson(Map<String, dynamic> json) {
    return MonthComparisonModel(
      monthLabel: json['month_label'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      incomeChange: (json['income_change'] as num?)?.toDouble() ?? 0.0,
      expenseChange: (json['expense_change'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
