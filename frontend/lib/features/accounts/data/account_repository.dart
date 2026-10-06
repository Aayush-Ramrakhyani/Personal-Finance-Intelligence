import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_models.dart';

class AccountRepository {
  final ApiClient _api;

  AccountRepository(this._api);

  Future<List<Account>> list() async {
    final res = await _api.get('/accounts');
    final items = res['data'] as List<dynamic>;
    return items.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Account> getById(String id) async {
    final res = await _api.get('/accounts/$id');
    return Account.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Account> create({
    required String name,
    required String accountType,
    required double openingBalance,
    String? bankName,
    String? lastFour,
  }) async {
    final res = await _api.post('/accounts', data: {
      'name': name,
      'account_type': accountType,
      'opening_balance': openingBalance,
      if (bankName != null) 'bank_name': bankName,
      if (lastFour != null) 'last_four': lastFour,
    });
    return Account.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Account> update(String id, Map<String, dynamic> data) async {
    final res = await _api.patch('/accounts/$id', data: data);
    return Account.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('/accounts/$id');
  }
}
