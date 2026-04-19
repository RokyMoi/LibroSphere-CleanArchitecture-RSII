import '../core/network/api_client.dart';
import '../data/models/author_model.dart';
import '../data/models/book_model.dart';
import '../data/models/paged_result.dart';
import '../data/models/review_model.dart';

class CatalogService {
  CatalogService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AuthorModel>> getAuthors() {
    return _apiClient.getAuthors();
  }

  Future<PagedResult<BookModel>> getBooks({String? searchTerm, String? accessToken}) {
    return _apiClient.getBooks(searchTerm: searchTerm, accessToken: accessToken);
  }

  Future<BookModel> getBook(String bookId, {String? accessToken}) {
    return _apiClient.getBook(bookId, accessToken);
  }

  Future<List<BookModel>> getRecommendations(String accessToken) {
    return _apiClient.getRecommendations(accessToken);
  }

  Future<PagedResult<ReviewModel>> getReviews(
    String bookId, {
    String? accessToken,
    int page = 1,
    int pageSize = 20,
  }) {
    return _apiClient.getReviews(
      bookId,
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
    );
  }
}
