import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/features/auth/data/auth_models.dart';
import 'package:personal_finance_intelligence/features/auth/data/auth_repository.dart';

// Current user state: null = not logged in
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final loggedIn = await _repo.isLoggedIn();
      if (loggedIn) {
        final user = await _repo.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final (user, _) = await _repo.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final (user, _) = await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    // Mark onboarding done — backend will update via PATCH /auth/me if available,
    // otherwise just reload user state so router can proceed.
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      // Proceed even if refresh fails
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}

// Convenience: get current user or null
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
