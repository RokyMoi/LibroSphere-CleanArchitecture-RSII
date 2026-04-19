import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_readers.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../models/authors_page_model.dart';

class AuthorsApiService {
  AuthorsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthorsPageModel> getAuthors(
    String token, {
    required int page,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.getMap(
      '/api/author',
      token: token,
      query: <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    return AuthorsPageModel(
      items: readItems(response).map(AdminAuthorModel.fromJson).toList(),
      page: readInt(response, <String>['page'], fallback: page),
      pageSize: readInt(response, <String>['pageSize'], fallback: pageSize),
      totalCount: readInt(response, <String>['totalCount']),
      totalPages: readInt(response, <String>['totalPages'], fallback: 1),
      hasPreviousPage: readBool(response, <String>['hasPreviousPage']),
      hasNextPage: readBool(response, <String>['hasNextPage']),
    );
  }

  Future<String> createAuthor({
    required String token,
    required String name,
    required String biography,
  }) async {
    final response = await _apiClient.postJson(
      '/api/author',
      token: token,
      body: <String, dynamic>{
        'name': name,
        'biography': biography,
      },
    );

    if (response is String && response.isNotEmpty) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      return readString(response, <String>['id', 'authorId', 'AuthorId']);
    }

    return response.toString();
  }

  Future<void> updateAuthor({
    required String token,
    required String authorId,
    required String name,
    required String biography,
  }) async {
    await _apiClient.putJson(
      '/api/author/$authorId',
      token: token,
      body: <String, dynamic>{
        'name': name,
        'biography': biography,
      },
    );
  }

  Future<void> deleteAuthor({
    required String token,
    required String authorId,
  }) {
    return _apiClient.delete(
      '/api/author/$authorId',
      token: token,
    );
  }
}
