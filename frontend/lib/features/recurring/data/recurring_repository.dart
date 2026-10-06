import 'package:dio/dio.dart';
import 'recurring_models.dart';

class RecurringRepository {
  final Dio _dio;

  RecurringRepository(this._dio);

  Future<List<RecurringTransactionModel>> getRecurring() async {
    final response = await _dio.get('/recurring');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => RecurringTransactionModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringTransactionModel> confirmRecurring(String id) async {
    final response = await _dio.post('/recurring/$id/confirm');
    return RecurringTransactionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<RecurringTransactionModel> rejectRecurring(String id) async {
    final response = await _dio.post('/recurring/$id/reject');
    return RecurringTransactionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecurring(String id) async {
    await _dio.delete('/recurring/$id');
  }
}
