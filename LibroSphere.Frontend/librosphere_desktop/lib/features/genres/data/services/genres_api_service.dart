import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/admin_genre_model.dart';
import '../models/genres_page_model.dart';

class GenresApiService {
  GenresApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<GenresPageModel> getGenres(
    String token, {
    required int page,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.getMap(
      '/api/genre',
      token: token,
      query: <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    return GenresPageModel(
      items: readItems(response).map(AdminGenreModel.fromJson).toList(),
      page: readInt(response, <String>['page'], fallback: page),
      pageSize: readInt(response, <String>['pageSize'], fallback: pageSize),
      totalCount: readInt(response, <String>['totalCount']),
      totalPages: readInt(response, <String>['totalPages'], fallback: 1),
      hasPreviousPage: readBool(response, <String>['hasPreviousPage']),
      hasNextPage: readBool(response, <String>['hasNextPage']),
    );
  }

  Future<String> createGenre({
    required String token,
    required String name,
  }) async {
    final response = await _apiClient.postJson(
      '/api/genre',
      token: token,
      body: <String, dynamic>{'name': name},
    );

    if (response is String && response.isNotEmpty) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      return readString(response, <String>['id', 'genreId', 'GenreId']);
    }

    return response.toString();
  }

  Future<void> updateGenre({
    required String token,
    required String genreId,
    required String name,
  }) {
    return _apiClient.putJson(
      '/api/genre/$genreId',
      token: token,
      body: <String, dynamic>{'name': name},
    );
  }

  Future<void> deleteGenre({
    required String token,
    required String genreId,
  }) {
    return _apiClient.delete(
      '/api/genre/$genreId',
      token: token,
    );
  }
}
