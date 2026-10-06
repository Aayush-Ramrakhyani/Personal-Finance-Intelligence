import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'recurring_models.dart';
import 'recurring_repository.dart';

final _recurringDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
});

final recurringRepositoryProvider =
    Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(_recurringDioProvider));
});

class RecurringNotifier
    extends AsyncNotifier<List<RecurringTransactionModel>> {
  @override
  Future<List<RecurringTransactionModel>> build() async {
    return ref.watch(recurringRepositoryProvider).getRecurring();
  }

  Future<void> confirm(String id) async {
    await ref.read(recurringRepositoryProvider).confirmRecurring(id);
    _refresh();
  }

  Future<void> reject(String id) async {
    await ref.read(recurringRepositoryProvider).rejectRecurring(id);
    _refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(recurringRepositoryProvider).deleteRecurring(id);
    _refresh();
  }

  void _refresh() {
    ref.invalidateSelf();
  }
}

final recurringNotifierProvider =
    AsyncNotifierProvider<RecurringNotifier, List<RecurringTransactionModel>>(
        RecurringNotifier.new);
