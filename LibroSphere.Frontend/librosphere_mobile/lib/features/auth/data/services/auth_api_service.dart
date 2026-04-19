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

  Future<void> logout(String accessToken) {
    return _apiClient.logout(accessToken);
  }
}
