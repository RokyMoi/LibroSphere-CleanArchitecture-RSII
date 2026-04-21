import '../../../../core/network/api_client.dart';

class SettingsApiService {
  final ApiClient _apiClient;
  final String _token;

  SettingsApiService(this._apiClient, this._token);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _apiClient.postJson(
      '/api/user/me/change-password',
      token: _token,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _apiClient.postJson(
      '/api/auth/create-admin',
      token: _token,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
  }
}
