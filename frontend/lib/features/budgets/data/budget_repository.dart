import 'package:dio/dio.dart';
import 'budget_models.dart';

class BudgetRepository {
  final Dio _dio;

  BudgetRepository(this._dio);

  Future<List<BudgetModel>> getBudgets() async {
    final response = await _dio.get('/budgets');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> createBudget(BudgetCreateRequest request) async {
    final response = await _dio.post(
      '/budgets',
      data: request.toJson(),
    );
    return BudgetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BudgetModel> updateBudget(
      String id, BudgetUpdateRequest request) async {
    final response = await _dio.put(
      '/budgets/$id',
      data: request.toJson(),
    );
    return BudgetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBudget(String id) async {
    await _dio.delete('/budgets/$id');
  }

  Future<BudgetProgressModel> getBudgetProgress(String id) async {
    final response = await _dio.get('/budgets/$id/progress');
    return BudgetProgressModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<BudgetProgressModel>> getAllBudgetsProgress() async {
    final response = await _dio.get('/budgets/progress');
    final data = response.data as List<dynamic>;
    return data
        .map((e) =>
            BudgetProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
