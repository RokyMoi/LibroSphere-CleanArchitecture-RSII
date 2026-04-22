import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/auth_session_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/auth_user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final AuthApiService _apiService;

  Future<Result<AuthSessionModel>> login(LoginRequest request) async {
    try {
      final tokens = await _apiService.login(request);
      final user = _apiService.decodeUserFromAccessToken(tokens.accessToken);
      return Success(AuthSessionModel(tokens: tokens, user: user));
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }

  Future<Result<AuthSessionModel>> register(RegisterRequest request) async {
    try {
      final tokens = await _apiService.register(request);
      final user = _apiService.decodeUserFromAccessToken(tokens.accessToken);
      return Success(AuthSessionModel(tokens: tokens, user: user));
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }

  Future<Result<AuthSessionModel>> restoreSession(
    AuthTokensModel tokens,
  ) async {
    try {
      final user = await _apiService.getCurrentUser(tokens.accessToken);
      return Success(AuthSessionModel(tokens: tokens, user: user));
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }

  AuthUserModel? tryDecodeUserFromAccessToken(String accessToken) {
    try {
      return _apiService.decodeUserFromAccessToken(accessToken);
    } catch (_) {
      return null;
    }
  }

  Future<Result<void>> logout(String accessToken) async {
    try {
      await _apiService.logout(accessToken);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> requestPasswordReset(String email) async {
    try {
      await _apiService.requestPasswordReset(email);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiService.resetPasswordWithCode(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult(Failure(message: exception.toString()));
    }
  }
}
