import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/admin_user_model.dart';
import '../models/users_page_model.dart';

class UsersApiService {
  UsersApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<UsersPageModel> getUsers(
    String token, {
    required int page,
    int pageSize = 12,
  }) async {
    final response = await _apiClient.getMap(
      '/api/user',
      token: token,
      query: <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    return UsersPageModel(
      items: readItems(response).map(AdminUserModel.fromJson).toList(),
      page: readInt(response, <String>['page'], fallback: page),
      pageSize: readInt(response, <String>['pageSize'], fallback: pageSize),
      totalCount: readInt(response, <String>['totalCount']),
      totalPages: readInt(response, <String>['totalPages'], fallback: 1),
      hasPreviousPage: readBool(response, <String>['hasPreviousPage']),
      hasNextPage: readBool(response, <String>['hasNextPage']),
    );
  }

  Future<void> deleteUser(String token, String userId) {
    return _apiClient.delete('/api/user/$userId', token: token);
  }
}
