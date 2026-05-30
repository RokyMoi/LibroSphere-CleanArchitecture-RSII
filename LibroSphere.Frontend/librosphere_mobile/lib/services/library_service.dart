import '../core/network/api_client.dart';
import '../data/models/library_entry.dart';
import '../data/models/paged_result.dart';

class LibraryService {
  LibraryService(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LibraryEntry>> getLibrary(
    String accessToken, {
    int page = 1,
    int pageSize = 20,
  }) {
    return _apiClient.getLibrary(accessToken, page: page, pageSize: pageSize);
  }

  Future<List<String>> getOwnedBookIds(String accessToken) {
    return _apiClient.getOwnedBookIds(accessToken);
  }

  Future<String> getReadUrl(String accessToken, String bookId) {
    return _apiClient.getReadUrl(accessToken, bookId);
  }

  Future<void> createReview(
    String accessToken,
    String bookId,
    int rating,
    String comment,
  ) {
    return _apiClient.createReview(accessToken, bookId, rating, comment);
  }
}
