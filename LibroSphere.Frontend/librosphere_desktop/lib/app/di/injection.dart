import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../features/authors/data/repositories/authors_repository.dart';
import '../../features/authors/data/services/authors_api_service.dart';
import '../../features/authors/presentation/viewmodels/authors_viewmodel.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/services/auth_api_service.dart';
import '../../features/books/data/repositories/books_repository.dart';
import '../../features/books/data/services/books_api_service.dart';
import '../../features/books/presentation/viewmodels/books_viewmodel.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/services/dashboard_api_service.dart';
import '../../features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../features/session/data/services/session_storage_service.dart';
import '../../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../features/users/data/repositories/users_repository.dart';
import '../../features/users/data/services/users_api_service.dart';
import '../../features/users/presentation/viewmodels/users_viewmodel.dart';

class AppInjection {
  static ApiClient createApiClient() => const ApiClient();

  static AdminSessionViewModel createSessionViewModel(
    SharedPreferences prefs,
  ) {
    final apiClient = createApiClient();

    return AdminSessionViewModel(
      AuthRepository(AuthApiService(apiClient)),
      SessionStorageService(prefs),
    );
  }

  static DashboardViewModel createDashboardViewModel(String token) {
    return DashboardViewModel(
      DashboardRepository(DashboardApiService(createApiClient())),
      token,
    );
  }

  static UsersViewModel createUsersViewModel(String token) {
    return UsersViewModel(
      UsersRepository(UsersApiService(createApiClient())),
      token,
    );
  }

  static BooksViewModel createBooksViewModel(String token) {
    return BooksViewModel(
      BooksRepository(BooksApiService(createApiClient())),
      token,
    );
  }

  static AuthorsViewModel createAuthorsViewModel(String token) {
    return AuthorsViewModel(
      AuthorsRepository(AuthorsApiService(createApiClient())),
      token,
    );
  }
}
