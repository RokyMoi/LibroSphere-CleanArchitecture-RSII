import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsFuture;
  AuthTokensModel? _cachedTokens;
  String? _cachedCartId;
  bool _hydrated = false;

  Future<void> warmUp() async {
    if (_hydrated) {
      return;
    }

    final prefs = await _getPrefs();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken != null && refreshToken != null) {
      _cachedTokens = AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } else {
      _cachedTokens = null;
    }

    _cachedCartId = prefs.getString('cartId');
    _hydrated = true;
  }

  Future<AuthTokensModel?> restoreTokens() async {
    await warmUp();
    return _cachedTokens;
  }

  Future<void> persistTokens(AuthTokensModel tokens) async {
    _cachedTokens = tokens;
    final prefs = await _getPrefs();
    await prefs.setString('accessToken', tokens.accessToken);
    await prefs.setString('refreshToken', tokens.refreshToken);
    _hydrated = true;
  }

  String? get cachedCartId => _cachedCartId;

  Future<String?> restoreCartId() async {
    await warmUp();
    return _cachedCartId;
  }

  Future<void> persistCartId(String cartId) async {
    _cachedCartId = cartId;
    final prefs = await _getPrefs();
    await prefs.setString('cartId', cartId);
    _hydrated = true;
  }

  Future<void> clearCart() async {
    _cachedCartId = null;
    final prefs = await _getPrefs();
    await prefs.remove('cartId');
    _hydrated = true;
  }

  Future<void> clearSession() async {
    _cachedTokens = null;
    _cachedCartId = null;
    final prefs = await _getPrefs();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('cartId');
    _hydrated = true;
  }

  Future<SharedPreferences> _getPrefs() {
    final existing = _prefs;
    if (existing != null) {
      return Future<SharedPreferences>.value(existing);
    }

    final future =
        _prefsFuture ??= SharedPreferences.getInstance().then((prefs) {
          _prefs = prefs;
          return prefs;
        });
    return future;
  }
}
