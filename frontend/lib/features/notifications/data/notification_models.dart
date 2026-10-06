import 'package:flutter/material.dart';

enum NotificationType {
  budgetAlert,
  insight,
  importDone,
  recurring,
  anomaly,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'budget_alert':
        return NotificationType.budgetAlert;
      case 'insight':
        return NotificationType.insight;
      case 'import_done':
        return NotificationType.importDone;
      case 'recurring':
        return NotificationType.recurring;
      case 'anomaly':
        return NotificationType.anomaly;
      default:
        return NotificationType.general;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.budgetAlert:
        return Icons.warning_rounded;
      case NotificationType.insight:
        return Icons.lightbulb_rounded;
      case NotificationType.importDone:
        return Icons.check_circle_rounded;
      case NotificationType.recurring:
        return Icons.repeat_rounded;
      case NotificationType.anomaly:
        return Icons.trending_up_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.budgetAlert:
        return const Color(0xFFFF5252);
      case NotificationType.insight:
        return const Color(0xFFFFC107);
      case NotificationType.importDone:
        return const Color(0xFF00C896);
      case NotificationType.recurring:
        return const Color(0xFF40C4FF);
      case NotificationType.anomaly:
        return const Color(0xFFFF9100);
      case NotificationType.general:
        return const Color(0xFF9E9E9E);
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
}
