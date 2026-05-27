import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthTokensModel? _cachedTokens;
  String? _cachedCartId;
  bool _hydrated = false;

  Future<void> warmUp() async {
    if (_hydrated) return;

    final accessToken = await _storage.read(key: 'accessToken');
    final refreshToken = await _storage.read(key: 'refreshToken');

    if (accessToken != null && refreshToken != null) {
      _cachedTokens = AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } else {
      _cachedTokens = null;
    }

    _cachedCartId = await _storage.read(key: 'cartId');
    _hydrated = true;
  }

  Future<AuthTokensModel?> restoreTokens() async {
    await warmUp();
    return _cachedTokens;
  }

  Future<void> persistTokens(AuthTokensModel tokens) async {
    _cachedTokens = tokens;
    await _storage.write(key: 'accessToken', value: tokens.accessToken);
    await _storage.write(key: 'refreshToken', value: tokens.refreshToken);
    _hydrated = true;
  }

  String? get cachedCartId => _cachedCartId;

  Future<String?> restoreCartId() async {
    await warmUp();
    return _cachedCartId;
  }

  Future<void> persistCartId(String cartId) async {
    _cachedCartId = cartId;
    await _storage.write(key: 'cartId', value: cartId);
    _hydrated = true;
  }

  Future<void> clearCart() async {
    _cachedCartId = null;
    await _storage.delete(key: 'cartId');
    _hydrated = true;
  }

  Future<void> clearSession() async {
    _cachedTokens = null;
    _cachedCartId = null;
    await _storage.deleteAll();
    _hydrated = true;
  }
}
