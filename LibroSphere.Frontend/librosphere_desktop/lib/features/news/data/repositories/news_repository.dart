import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/admin_news_model.dart';
import '../services/news_api_service.dart';

class NewsRepository {
  NewsRepository(this._apiService);

  final NewsApiService _apiService;

  Future<Result<List<AdminNewsModel>>> getNews(
    String token, {
    int take = 50,
  }) async {
    try {
      final news = await _apiService.getNews(token, take: take);
      return Success<List<AdminNewsModel>>(news);
    } on AppException catch (e) {
      return ErrorResult<List<AdminNewsModel>>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<List<AdminNewsModel>>(Failure(message: e.toString()));
    }
  }

  Future<Result<void>> createNews({
    required String token,
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    if (title.trim().isEmpty) {
      return const ErrorResult<void>(Failure(message: 'Title is required.'));
    }
    if (text.trim().isEmpty) {
      return const ErrorResult<void>(Failure(message: 'Content is required.'));
    }

    try {
      await _apiService.createNews(
        token: token,
        title: title.trim(),
        text: text.trim(),
        imageUrl: imageUrl.trim(),
      );
      return const Success<void>(null);
    } on AppException catch (e) {
      return ErrorResult<void>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<void>(Failure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteNews({
    required String token,
    required String newsId,
  }) async {
    try {
      await _apiService.deleteNews(token: token, newsId: newsId);
      return const Success<void>(null);
    } on AppException catch (e) {
      return ErrorResult<void>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<void>(Failure(message: e.toString()));
    }
  }

  Future<Result<String>> uploadNewsImage({
    required String token,
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final imageUrl = await _apiService.uploadNewsImage(
        token: token,
        imageBytes: imageBytes,
        filename: filename,
        contentType: contentType,
      );
      return Success<String>(imageUrl);
    } on AppException catch (e) {
      return ErrorResult<String>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<String>(Failure(message: e.toString()));
    }
  }
}
