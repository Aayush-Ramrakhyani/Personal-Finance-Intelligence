import 'package:flutter/material.dart';

enum RecurringFrequency { daily, weekly, biweekly, monthly, quarterly, yearly }

enum RecurringConfidenceLevel { high, medium, low }

enum RecurringStatus { confirmed, unconfirmed, rejected }

class RecurringTransactionModel {
  final String id;
  final String merchantName;
  final String? category;
  final String? categoryIcon;
  final double amount;
  final RecurringFrequency frequency;
  final DateTime nextExpectedDate;
  final DateTime lastSeen;
  final RecurringConfidenceLevel confidence;
  final RecurringStatus status;
  final int occurrenceCount;

  const RecurringTransactionModel({
    required this.id,
    required this.merchantName,
    this.category,
    this.categoryIcon,
    required this.amount,
    required this.frequency,
    required this.nextExpectedDate,
    required this.lastSeen,
    required this.confidence,
    required this.status,
    required this.occurrenceCount,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String,
      category: json['category'] as String?,
      categoryIcon: json['category_icon'] as String?,
      amount: (json['amount'] as num).toDouble(),
      frequency: _parseFrequency(json['frequency'] as String),
      nextExpectedDate:
          DateTime.parse(json['next_expected_date'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      confidence: _parseConfidence(json['confidence'] as String),
      status: _parseStatus(json['status'] as String),
      occurrenceCount: json['occurrence_count'] as int? ?? 1,
    );
  }

  static RecurringFrequency _parseFrequency(String freq) {
    switch (freq) {
      case 'daily':
        return RecurringFrequency.daily;
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'biweekly':
        return RecurringFrequency.biweekly;
      case 'quarterly':
        return RecurringFrequency.quarterly;
      case 'yearly':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.monthly;
    }
  }

  static RecurringConfidenceLevel _parseConfidence(String conf) {
    switch (conf) {
      case 'high':
        return RecurringConfidenceLevel.high;
      case 'low':
        return RecurringConfidenceLevel.low;
      default:
        return RecurringConfidenceLevel.medium;
    }
  }

  static RecurringStatus _parseStatus(String status) {
    switch (status) {
      case 'confirmed':
        return RecurringStatus.confirmed;
      case 'rejected':
        return RecurringStatus.rejected;
      default:
        return RecurringStatus.unconfirmed;
    }
  }

  /// Annual cost based on frequency
  double get annualCost {
    switch (frequency) {
      case RecurringFrequency.daily:
        return amount * 365;
      case RecurringFrequency.weekly:
        return amount * 52;
      case RecurringFrequency.biweekly:
        return amount * 26;
      case RecurringFrequency.monthly:
        return amount * 12;
      case RecurringFrequency.quarterly:
        return amount * 4;
      case RecurringFrequency.yearly:
        return amount;
    }
  }

  /// Monthly cost
  double get monthlyCost => annualCost / 12;

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Bi-weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  Color get confidenceColor {
    switch (confidence) {
      case RecurringConfidenceLevel.high:
        return const Color(0xFF00C896);
      case RecurringConfidenceLevel.medium:
        return const Color(0xFFFFC107);
      case RecurringConfidenceLevel.low:
        return const Color(0xFFFF5252);
    }
  }

  bool get isConfirmed => status == RecurringStatus.confirmed;
  bool get isUnconfirmed => status == RecurringStatus.unconfirmed;
  bool get isRejected => status == RecurringStatus.rejected;
}
