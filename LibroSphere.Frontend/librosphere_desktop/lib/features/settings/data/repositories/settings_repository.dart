import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../services/settings_api_service.dart';

class SettingsRepository {
  final SettingsApiService _apiService;

  SettingsRepository(this._apiService);

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      return const Success(null);
    } on AppException catch (e) {
      return ErrorResult(e.message);
    } catch (e) {
      return ErrorResult(e.toString());
    }
  }

  Future<Result<void>> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      await _apiService.createAdmin(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      return const Success(null);
    } on AppException catch (e) {
      return ErrorResult(e.message);
    } catch (e) {
      return ErrorResult(e.toString());
    }
  }
}
