import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'budget_models.dart';
import 'budget_repository.dart';

// ---------------------------------------------------------------------------
// Core providers
// ---------------------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
  return dio;
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Budget list with progress
// ---------------------------------------------------------------------------

final budgetsProgressProvider =
    FutureProvider<List<BudgetProgressModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getAllBudgetsProgress();
});

// ---------------------------------------------------------------------------
// Single budget progress
// ---------------------------------------------------------------------------

final budgetProgressProvider =
    FutureProvider.family<BudgetProgressModel, String>((ref, id) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgetProgress(id);
});

// ---------------------------------------------------------------------------
// Budget CRUD notifier
// ---------------------------------------------------------------------------

class BudgetNotifier extends AsyncNotifier<List<BudgetModel>> {
  @override
  Future<List<BudgetModel>> build() async {
    return ref.watch(budgetRepositoryProvider).getBudgets();
  }

  Future<void> createBudget(BudgetCreateRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).createBudget(request);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
    ref.invalidate(budgetsProgressProvider);
  }

  Future<void> updateBudget(String id, BudgetUpdateRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).updateBudget(id, request);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
    ref.invalidate(budgetsProgressProvider);
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(budgetRepositoryProvider).deleteBudget(id);
      return ref.read(budgetRepositoryProvider).getBudgets();
    });
    ref.invalidate(budgetsProgressProvider);
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider<BudgetNotifier, List<BudgetModel>>(
        BudgetNotifier.new);
