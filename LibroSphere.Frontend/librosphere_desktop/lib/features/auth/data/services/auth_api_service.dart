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
}
