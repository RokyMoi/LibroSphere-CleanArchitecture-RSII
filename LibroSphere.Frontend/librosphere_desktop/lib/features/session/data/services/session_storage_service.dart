import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../auth/data/models/auth_tokens_model.dart';

class SessionStorageService {
  static const _storage = FlutterSecureStorage(
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
    mOptions: MacOsOptions(),
  );

  AuthTokensModel? _cachedTokens;
  bool _hydrated = false;

  Future<void> warmUp() async {
    if (_hydrated) return;

    final accessToken = await _storage.read(key: 'adminAccessToken');
    final refreshToken = await _storage.read(key: 'adminRefreshToken');

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
    await _storage.write(key: 'adminAccessToken', value: tokens.accessToken);
    await _storage.write(key: 'adminRefreshToken', value: tokens.refreshToken);
    _hydrated = true;
  }

  Future<void> clearSession() async {
    _cachedTokens = null;
    await _storage.deleteAll();
    _hydrated = true;
  }
}
