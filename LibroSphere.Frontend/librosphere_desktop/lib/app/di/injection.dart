import 'package:flutter/foundation.dart';

import '../../core/localization/admin_language_controller.dart';
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
import '../../features/genres/data/repositories/genres_repository.dart';
import '../../features/genres/data/services/genres_api_service.dart';
import '../../features/genres/presentation/viewmodels/genres_viewmodel.dart';
import '../../features/admin_notes/data/repositories/admin_notes_repository.dart';
import '../../features/admin_notes/data/services/admin_notes_api_service.dart';
import '../../features/admin_notes/presentation/viewmodels/admin_notes_viewmodel.dart';
import '../../features/orders/data/repositories/orders_repository.dart';
import '../../features/orders/data/services/orders_api_service.dart';
import '../../features/orders/presentation/viewmodels/orders_viewmodel.dart';
import '../../features/reports/presentation/viewmodels/reports_viewmodel.dart';
import '../../features/session/data/services/session_storage_service.dart';
import '../../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/data/services/settings_api_service.dart';
import '../../features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../features/users/data/repositories/users_repository.dart';
import '../../features/users/data/services/users_api_service.dart';
import '../../features/users/presentation/viewmodels/users_viewmodel.dart';

class AppInjection {
  static final ApiClient _sharedApiClient = ApiClient();

  static ApiClient createApiClient() => _sharedApiClient;

  static AdminSessionViewModel createSessionViewModel() {
    final apiClient = createApiClient();

    return AdminSessionViewModel(
      AuthRepository(AuthApiService(apiClient)),
      SessionStorageService(),
    );
  }

  static AdminLanguageController createAdminLanguageController() {
    return AdminLanguageController();
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

  static BooksViewModel createBooksViewModel(
    String token, {
    AsyncCallback? onDataChanged,
  }) {
    return BooksViewModel(
      BooksRepository(BooksApiService(createApiClient())),
      token,
      onDataChanged: onDataChanged,
    );
  }

  static GenresViewModel createGenresViewModel(
    String token, {
    AsyncCallback? onDataChanged,
  }) {
    return GenresViewModel(
      GenresRepository(GenresApiService(createApiClient())),
      token,
      onDataChanged: onDataChanged,
    );
  }

  static AuthorsViewModel createAuthorsViewModel(
    String token, {
    AsyncCallback? onDataChanged,
  }) {
    return AuthorsViewModel(
      AuthorsRepository(AuthorsApiService(createApiClient())),
      token,
      onDataChanged: onDataChanged,
    );
  }

  static ReportsViewModel createReportsViewModel(String token) {
    return ReportsViewModel(
      dashboardRepository: DashboardRepository(
        DashboardApiService(createApiClient()),
      ),
      booksRepository: BooksRepository(BooksApiService(createApiClient())),
      token: token,
    );
  }

  static OrdersViewModel createOrdersViewModel(String token) {
    return OrdersViewModel(
      OrdersRepository(OrdersApiService(createApiClient())),
      token,
    );
  }

  static AdminNotesViewModel createAdminNotesViewModel(String token) {
    return AdminNotesViewModel(
      AdminNotesRepository(AdminNotesApiService(createApiClient())),
      token,
    );
  }

  static SettingsViewModel createSettingsViewModel(String token) {
    return SettingsViewModel(
      SettingsRepository(SettingsApiService(createApiClient(), token)),
    );
  }
}
