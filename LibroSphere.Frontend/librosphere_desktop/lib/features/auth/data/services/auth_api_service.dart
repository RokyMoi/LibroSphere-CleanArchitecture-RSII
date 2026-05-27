import 'dart:convert';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request.dart';

class AuthApiService {
  AuthApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokensModel> login(LoginRequest request) async {
    final response = await _apiClient.postJson(
      '/api/auth/login',
      body: request.toJson(),
    );

    if (response is Map<String, dynamic>) {
      return AuthTokensModel.fromJson(response);
    }

    throw const AppException(
      message: 'Invalid login response received from backend.',
    );
  }

  bool decodeAndCheckToken(String accessToken) {
    try {
      final segments = accessToken.split('.');
      if (segments.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;
      final exp = payload['exp'];
      if (exp is! int) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }
}
