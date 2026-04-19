import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final AuthApiService _apiService;

  Future<Result<AuthTokensModel>> login(LoginRequest request) async {
    try {
      final tokens = await _apiService.login(request);
      return Success<AuthTokensModel>(tokens);
    } on AppException catch (exception) {
      return ErrorResult<AuthTokensModel>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<AuthTokensModel>(
        Failure(message: exception.toString()),
      );
    }
  }
}
