import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../models/authors_page_model.dart';
import '../services/authors_api_service.dart';

class AuthorsRepository {
  AuthorsRepository(this._apiService);

  final AuthorsApiService _apiService;

  Future<Result<AuthorsPageModel>> getAuthors(
    String token, {
    required int page,
    int pageSize = 10,
    String? searchTerm,
  }) async {
    try {
      final authors = await _apiService.getAuthors(
        token,
        page: page,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );
      return Success<AuthorsPageModel>(authors);
    } on AppException catch (exception) {
      return ErrorResult<AuthorsPageModel>(
        Failure.fromException(exception),
      );
    } catch (exception) {
      return ErrorResult<AuthorsPageModel>(
        Failure(message: exception.toString()),
      );
    }
  }

  Future<Result<void>> saveAuthor({
    required String token,
    required AdminAuthorModel? existingAuthor,
    required String name,
    required String biography,
  }) async {
    final normalizedName = name.trim();
    final normalizedBiography = biography.trim();

    if (normalizedName.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'Author name is required.'),
      );
    }

    if (normalizedBiography.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'Biography is required.'),
      );
    }

    try {
      if (existingAuthor == null) {
        await _apiService.createAuthor(
          token: token,
          name: normalizedName,
          biography: normalizedBiography,
        );
      } else {
        await _apiService.updateAuthor(
          token: token,
          authorId: existingAuthor.id,
          name: normalizedName,
          biography: normalizedBiography,
        );
      }

      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> deleteAuthor({
    required String token,
    required AdminAuthorModel author,
  }) async {
    try {
      await _apiService.deleteAuthor(token: token, authorId: author.id);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }
}
