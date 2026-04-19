import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  SessionStorageService(this._prefs);

  final SharedPreferences _prefs;

  AuthTokensModel? restoreTokens() {
    final accessToken = _prefs.getString('adminAccessToken');
    final refreshToken = _prefs.getString('adminRefreshToken');

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> persistTokens(AuthTokensModel tokens) async {
    await _prefs.setString('adminAccessToken', tokens.accessToken);
    await _prefs.setString('adminRefreshToken', tokens.refreshToken);
  }

  Future<void> clearSession() async {
    await _prefs.remove('adminAccessToken');
    await _prefs.remove('adminRefreshToken');
  }
}
