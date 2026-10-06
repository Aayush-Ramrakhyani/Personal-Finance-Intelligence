import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_models.dart';

class TransactionRepository {
  final ApiClient _api;

  TransactionRepository(this._api);

  Future<PaginatedTransactions> list({
    TransactionFilter? filter,
    int page = 1,
  }) async {
    final params = filter?.toQuery(page) ?? {'page': page, 'page_size': 20};
    final res = await _api.get('/transactions', params: params);
    return PaginatedTransactions.fromJson(res);
  }

  Future<Transaction> getById(String id) async {
    final res = await _api.get('/transactions/$id');
    return Transaction.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Transaction> create({
    required String accountId,
    required String type,
    required double amount,
    required DateTime date,
    String? categoryId,
    String? description,
    String? merchant,
    String? referenceNumber,
  }) async {
    final res = await _api.post('/transactions', data: {
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'transaction_date': date.toIso8601String().substring(0, 10),
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      if (referenceNumber != null) 'reference_number': referenceNumber,
    });
    return Transaction.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    await _api.post('/transfers', data: {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'transaction_date': date.toIso8601String().substring(0, 10),
      if (description != null) 'description': description,
    });
  }

  Future<Transaction> update(String id, Map<String, dynamic> data) async {
    final res = await _api.patch('/transactions/$id', data: data);
    return Transaction.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('/transactions/$id');
  }
}
