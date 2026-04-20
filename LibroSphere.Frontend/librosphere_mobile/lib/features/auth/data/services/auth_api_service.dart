import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../models/auth_tokens_model.dart';
import '../models/auth_user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthApiService {
  AuthApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokensModel> login(LoginRequest request) async {
    final response = await _apiClient.login(request.email, request.password);
    return AuthTokensModel.fromJson(response);
  }

  Future<AuthTokensModel> register(RegisterRequest request) async {
    final response = await _apiClient.register(
      request.firstName,
      request.lastName,
      request.email,
      request.password,
    );
    return AuthTokensModel.fromJson(response);
  }

  Future<AuthUserModel> getCurrentUser(String accessToken) async {
    final response = await _apiClient.getCurrentUser(accessToken);
    return AuthUserModel.fromJson(response);
  }

  AuthUserModel decodeUserFromAccessToken(String accessToken) {
    final segments = accessToken.split('.');
    if (segments.length != 3) {
      throw const FormatException('Invalid access token payload.');
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid access token claims.');
    }

    String readClaim(List<String> keys) {
      for (final key in keys) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      throw FormatException('Missing JWT claim: ${keys.first}');
    }

    return AuthUserModel(
      id: readClaim(const <String>[
        'sub',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      ]),
      firstName: readClaim(const <String>[
        'firstName',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
      ]),
      lastName: readClaim(const <String>[
        'lastName',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
      ]),
      email: readClaim(const <String>[
        'email',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
      ]),
    );
  }

  Future<void> logout(String accessToken) {
    return _apiClient.logout(accessToken);
  }
}
