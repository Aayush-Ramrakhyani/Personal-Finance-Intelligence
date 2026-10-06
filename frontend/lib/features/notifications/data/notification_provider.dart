import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

final _notificationDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(_notificationDioProvider));
});

class NotificationNotifier
    extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return ref
        .watch(notificationRepositoryProvider)
        .getNotifications();
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markAsRead(id);
    } catch (_) {
      // Revert on failure
      ref.invalidateSelf();
    }
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(
        current.map((n) => n.copyWith(isRead: true)).toList());
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markAllAsRead();
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    try {
      await ref.read(notificationRepositoryProvider).clearAll();
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
        NotificationNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationNotifierProvider);
  return notifications.valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});
