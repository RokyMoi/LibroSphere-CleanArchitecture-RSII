import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  SessionStorageService(this._prefs);

  final SharedPreferences _prefs;

  AuthTokensModel? restoreTokens() {
    final accessToken = _prefs.getString('accessToken');
    final refreshToken = _prefs.getString('refreshToken');

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokensModel(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> persistTokens(AuthTokensModel tokens) async {
    await _prefs.setString('accessToken', tokens.accessToken);
    await _prefs.setString('refreshToken', tokens.refreshToken);
  }

  String? restoreCartId() {
    return _prefs.getString('cartId');
  }

  Future<void> persistCartId(String cartId) async {
    await _prefs.setString('cartId', cartId);
  }

  Future<void> clearCart() async {
    await _prefs.remove('cartId');
  }

  Future<void> clearSession() async {
    await _prefs.remove('accessToken');
    await _prefs.remove('refreshToken');
    await _prefs.remove('cartId');
  }
}
