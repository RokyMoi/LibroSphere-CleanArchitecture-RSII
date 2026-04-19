import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/users_page_model.dart';
import '../services/users_api_service.dart';

class UsersRepository {
  UsersRepository(this._apiService);

  final UsersApiService _apiService;

  Future<Result<UsersPageModel>> getUsers(
    String token, {
    required int page,
    int pageSize = 12,
  }) async {
    try {
      final users = await _apiService.getUsers(
        token,
        page: page,
        pageSize: pageSize,
      );
      return Success<UsersPageModel>(users);
    } on AppException catch (exception) {
      return ErrorResult<UsersPageModel>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<UsersPageModel>(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> deleteUser(String token, String userId) async {
    try {
      await _apiService.deleteUser(token, userId);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }
}
