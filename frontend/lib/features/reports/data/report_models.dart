class MonthlyReportModel {
  final int year;
  final int month;
  final String monthLabel;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final String aiNarrative;
  final List<ReportCategoryModel> categoryBreakdown;
  final List<ReportBudgetPerformanceModel> budgetPerformance;
  final List<ReportTransactionModel> notableTransactions;
  final MonthComparisonReportModel? comparisonWithPrevious;
  final List<ReportRecurringModel> recurringExpenses;
  final List<ReportAnomalyModel> anomalies;

  const MonthlyReportModel({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.aiNarrative,
    required this.categoryBreakdown,
    required this.budgetPerformance,
    required this.notableTransactions,
    this.comparisonWithPrevious,
    required this.recurringExpenses,
    required this.anomalies,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyReportModel(
      year: json['year'] as int,
      month: json['month'] as int,
      monthLabel: json['month_label'] as String,
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      netSavings: (json['net_savings'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
      aiNarrative: json['ai_narrative'] as String? ?? '',
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>?)
              ?.map((e) =>
                  ReportCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      budgetPerformance: (json['budget_performance'] as List<dynamic>?)
              ?.map((e) => ReportBudgetPerformanceModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      notableTransactions: (json['notable_transactions'] as List<dynamic>?)
              ?.map((e) =>
                  ReportTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparisonWithPrevious: json['comparison_with_previous'] != null
          ? MonthComparisonReportModel.fromJson(
              json['comparison_with_previous'] as Map<String, dynamic>)
          : null,
      recurringExpenses: (json['recurring_expenses'] as List<dynamic>?)
              ?.map((e) =>
                  ReportRecurringModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      anomalies: (json['anomalies'] as List<dynamic>?)
              ?.map((e) =>
                  ReportAnomalyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReportCategoryModel {
  final String category;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final int transactionCount;

  const ReportCategoryModel({
    required this.category,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  factory ReportCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReportCategoryModel(
      category: json['category'] as String,
      categoryIcon: json['category_icon'] as String? ?? 'category',
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
    );
  }
}

class ReportBudgetPerformanceModel {
  final String budgetId;
  final String category;
  final double budgeted;
  final double spent;
  final double percentageUsed;
  final bool isOverBudget;

  const ReportBudgetPerformanceModel({
    required this.budgetId,
    required this.category,
    required this.budgeted,
    required this.spent,
    required this.percentageUsed,
    required this.isOverBudget,
  });

  factory ReportBudgetPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ReportBudgetPerformanceModel(
      budgetId: json['budget_id'] as String,
      category: json['category'] as String,
      budgeted: (json['budgeted'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      isOverBudget: json['is_over_budget'] as bool? ?? false,
    );
  }
}

class ReportTransactionModel {
  final String id;
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String reason;

  const ReportTransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.reason,
  });

  factory ReportTransactionModel.fromJson(Map<String, dynamic> json) {
    return ReportTransactionModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      reason: json['reason'] as String? ?? '',
    );
  }

  bool get isExpense => type == 'expense';
}

class MonthComparisonReportModel {
  final String previousMonthLabel;
  final double incomeDiff;
  final double expenseDiff;
  final double savingsDiff;
  final double incomeChangePercent;
  final double expenseChangePercent;

  const MonthComparisonReportModel({
    required this.previousMonthLabel,
    required this.incomeDiff,
    required this.expenseDiff,
    required this.savingsDiff,
    required this.incomeChangePercent,
    required this.expenseChangePercent,
  });

  factory MonthComparisonReportModel.fromJson(Map<String, dynamic> json) {
    return MonthComparisonReportModel(
      previousMonthLabel: json['previous_month_label'] as String,
      incomeDiff: (json['income_diff'] as num).toDouble(),
      expenseDiff: (json['expense_diff'] as num).toDouble(),
      savingsDiff: (json['savings_diff'] as num).toDouble(),
      incomeChangePercent: (json['income_change_percent'] as num).toDouble(),
      expenseChangePercent:
          (json['expense_change_percent'] as num).toDouble(),
    );
  }
}

class ReportRecurringModel {
  final String merchantName;
  final double amount;
  final String frequency;
  final double annualCost;

  const ReportRecurringModel({
    required this.merchantName,
    required this.amount,
    required this.frequency,
    required this.annualCost,
  });

  factory ReportRecurringModel.fromJson(Map<String, dynamic> json) {
    return ReportRecurringModel(
      merchantName: json['merchant_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'] as String,
      annualCost: (json['annual_cost'] as num).toDouble(),
    );
  }
}

class ReportAnomalyModel {
  final String category;
  final String description;
  final double amount;
  final double expectedAmount;
  final double deviationPercent;

  const ReportAnomalyModel({
    required this.category,
    required this.description,
    required this.amount,
    required this.expectedAmount,
    required this.deviationPercent,
  });

  factory ReportAnomalyModel.fromJson(Map<String, dynamic> json) {
    return ReportAnomalyModel(
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      deviationPercent: (json['deviation_percent'] as num).toDouble(),
    );
  }
}
