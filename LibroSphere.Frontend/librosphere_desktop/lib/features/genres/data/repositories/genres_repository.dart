import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/admin_genre_model.dart';
import '../models/genres_page_model.dart';
import '../services/genres_api_service.dart';

class GenresRepository {
  GenresRepository(this._apiService);

  final GenresApiService _apiService;

  Future<Result<GenresPageModel>> getGenres(
    String token, {
    required int page,
    int pageSize = 10,
  }) async {
    try {
      final genres = await _apiService.getGenres(
        token,
        page: page,
        pageSize: pageSize,
      );
      return Success<GenresPageModel>(genres);
    } on AppException catch (exception) {
      return ErrorResult<GenresPageModel>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<GenresPageModel>(
        Failure(message: exception.toString()),
      );
    }
  }

  Future<Result<void>> saveGenre({
    required String token,
    required AdminGenreModel? existingGenre,
    required String name,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'Genre name is required.'),
      );
    }

    try {
      if (existingGenre == null) {
        await _apiService.createGenre(
          token: token,
          name: normalizedName,
        );
      } else {
        await _apiService.updateGenre(
          token: token,
          genreId: existingGenre.id,
          name: normalizedName,
        );
      }

      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> deleteGenre({
    required String token,
    required AdminGenreModel genre,
  }) async {
    try {
      await _apiService.deleteGenre(token: token, genreId: genre.id);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }
}
