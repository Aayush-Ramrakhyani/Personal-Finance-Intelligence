import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_models.dart';
import 'package:personal_finance_intelligence/features/accounts/data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.read(apiClientProvider)),
);

final accountListProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepositoryProvider).list();
});

final accountDetailProvider =
    FutureProvider.autoDispose.family<Account, String>((ref, id) async {
  return ref.read(accountRepositoryProvider).getById(id);
});
