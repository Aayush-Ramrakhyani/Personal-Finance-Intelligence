import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_models.dart';
import 'package:personal_finance_intelligence/features/transactions/data/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.read(apiClientProvider)),
);

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

class TransactionListNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repo;
  final Ref _ref;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  final List<Transaction> _items = [];

  TransactionListNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    _ref.listen<TransactionFilter>(
      transactionFilterProvider,
      (_, __) => load(reset: true),
    );
    load();
  }

  Future<void> load({bool reset = false}) async {
    if (_loading) return;
    if (!_hasMore && !reset) return;

    if (reset) {
      _page = 1;
      _hasMore = true;
      _items.clear();
      state = const AsyncValue.loading();
    }

    _loading = true;
    try {
      final filter = _ref.read(transactionFilterProvider);
      final result = await _repo.list(filter: filter, page: _page);
      _items.addAll(result.items);
      _hasMore = result.hasMore;
      _page++;
      state = AsyncValue.data(List.from(_items));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loading = false;
    }
  }

  Future<void> refresh() => load(reset: true);

  bool get hasMore => _hasMore;

  Future<void> deleteTransaction(String id) async {
    await _repo.delete(id);
    _items.removeWhere((t) => t.id == id);
    state = AsyncValue.data(List.from(_items));
  }
}

final AutoDisposeStateNotifierProvider<TransactionListNotifier, AsyncValue<List<Transaction>>>
    transactionListProvider =
    StateNotifierProvider.autoDispose<TransactionListNotifier, AsyncValue<List<Transaction>>>(
  (ref) => TransactionListNotifier(ref.read(transactionRepositoryProvider), ref),
);
