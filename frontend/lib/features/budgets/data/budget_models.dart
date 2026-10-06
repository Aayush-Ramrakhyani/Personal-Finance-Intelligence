import 'package:flutter/material.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final String categoryIcon;
  final double amount;
  final String period; // monthly, weekly, yearly
  final double alertThreshold; // percentage 0-100
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.categoryIcon,
    required this.amount,
    required this.period,
    required this.alertThreshold,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      categoryIcon: json['category_icon'] as String? ?? 'category',
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      alertThreshold: (json['alert_threshold'] as num?)?.toDouble() ?? 80.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'category_icon': categoryIcon,
        'amount': amount,
        'period': period,
        'alert_threshold': alertThreshold,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? categoryIcon,
    double? amount,
    String? period,
    double? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetCreateRequest {
  final String category;
  final String categoryIcon;
  final double amount;
  final String period;
  final double alertThreshold;

  const BudgetCreateRequest({
    required this.category,
    required this.categoryIcon,
    required this.amount,
    required this.period,
    this.alertThreshold = 80.0,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'category_icon': categoryIcon,
        'amount': amount,
        'period': period,
        'alert_threshold': alertThreshold,
      };
}

class BudgetUpdateRequest {
  final double? amount;
  final String? period;
  final double? alertThreshold;
  final bool? isActive;

  const BudgetUpdateRequest({
    this.amount,
    this.period,
    this.alertThreshold,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (amount != null) map['amount'] = amount;
    if (period != null) map['period'] = period;
    if (alertThreshold != null) map['alert_threshold'] = alertThreshold;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}

class BudgetProgressModel {
  final String budgetId;
  final BudgetModel budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<BudgetTransactionModel> recentTransactions;

  const BudgetProgressModel({
    required this.budgetId,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
    required this.recentTransactions,
  });

  factory BudgetProgressModel.fromJson(Map<String, dynamic> json) {
    return BudgetProgressModel(
      budgetId: json['budget_id'] as String,
      budget: BudgetModel.fromJson(json['budget'] as Map<String, dynamic>),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentageUsed: (json['percentage_used'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((e) =>
                  BudgetTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Status color based on percentage used
  Color get statusColor {
    if (percentageUsed < 75) return const Color(0xFF00C896);
    if (percentageUsed < 90) return const Color(0xFFFFC107);
    return const Color(0xFFFF5252);
  }

  /// True if over budget
  bool get isOverBudget => spent > budget.amount;
}

class BudgetTransactionModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String accountName;

  const BudgetTransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.accountName,
  });

  factory BudgetTransactionModel.fromJson(Map<String, dynamic> json) {
    return BudgetTransactionModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      accountName: json['account_name'] as String? ?? '',
    );
  }
}
