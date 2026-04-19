import '../core/network/api_client.dart';
import '../data/models/library_entry.dart';
import '../data/models/paged_result.dart';

class LibraryService {
  LibraryService(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<LibraryEntry>> getLibrary(String accessToken) {
    return _apiClient.getLibrary(accessToken);
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
