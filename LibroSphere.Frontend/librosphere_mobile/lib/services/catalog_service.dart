import '../core/network/api_client.dart';
import '../data/models/author_model.dart';
import '../data/models/book_model.dart';
import '../data/models/genre_model.dart';
import '../data/models/home_feed_model.dart';
import '../data/models/paged_result.dart';
import '../data/models/review_model.dart';

class CatalogService {
  CatalogService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AuthorModel>> getAuthors() {
    return _apiClient.getAuthors();
  }

  Future<List<GenreModel>> getGenres() {
    return _apiClient.getGenres();
  }

  Future<PagedResult<BookModel>> getBooks({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? authorId,
    String? genreId,
    double? minPrice,
    double? maxPrice,
    String? accessToken,
  }) {
    return _apiClient.getBooks(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      authorId: authorId,
      genreId: genreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      accessToken: accessToken,
    );
  }

  Future<HomeFeedModel> getHomeFeed({
    int page = 1,
    int pageSize = 8,
    int takeRecommendations = 4,
    String? searchTerm,
    String? accessToken,
  }) {
    return _apiClient.getHomeFeed(
      page: page,
      pageSize: pageSize,
      takeRecommendations: takeRecommendations,
      searchTerm: searchTerm,
      accessToken: accessToken,
    );
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
