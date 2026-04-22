import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsFuture;
  AuthTokensModel? _cachedTokens;
  bool _hydrated = false;

  Future<void> warmUp() async {
    if (_hydrated) {
      return;
    }

    final prefs = await _getPrefs();
    final accessToken = prefs.getString('adminAccessToken');
    final refreshToken = prefs.getString('adminRefreshToken');

    if (accessToken != null && refreshToken != null) {
      _cachedTokens = AuthTokensModel(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } else {
      _cachedTokens = null;
    }

    _hydrated = true;
  }

  Future<AuthTokensModel?> restoreTokens() async {
    await warmUp();
    return _cachedTokens;
  }

  Future<void> persistTokens(AuthTokensModel tokens) async {
    _cachedTokens = tokens;
    final prefs = await _getPrefs();
    await prefs.setString('adminAccessToken', tokens.accessToken);
    await prefs.setString('adminRefreshToken', tokens.refreshToken);
    _hydrated = true;
  }

  Future<void> clearSession() async {
    _cachedTokens = null;
    final prefs = await _getPrefs();
    await prefs.remove('adminAccessToken');
    await prefs.remove('adminRefreshToken');
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
