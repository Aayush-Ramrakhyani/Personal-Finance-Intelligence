import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_intelligence/core/constants/app_constants.dart';
import 'package:personal_finance_intelligence/core/network/api_client.dart';
import 'package:personal_finance_intelligence/core/storage/secure_storage.dart';
import 'package:personal_finance_intelligence/features/auth/data/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(secureStorageProvider));
});

class AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthRepository(this._api, this._storage);

  Future<(UserModel, TokenModel)> login(String email, String password) async {
    final resp = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = resp['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = TokenModel.fromJson(data);
    await _saveTokens(tokens);
    return (user, tokens);
  }

  Future<(UserModel, TokenModel)> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final resp = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    });
    final data = resp['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = TokenModel.fromJson(data);
    await _saveTokens(tokens);
    return (user, tokens);
  }

  Future<UserModel> getCurrentUser() async {
    final resp = await _api.get('/auth/me');
    return UserModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    return token != null;
  }

  Future<void> _saveTokens(TokenModel tokens) async {
    await _storage.write(AppConstants.accessTokenKey, tokens.accessToken);
    await _storage.write(AppConstants.refreshTokenKey, tokens.refreshToken);
  }
}
