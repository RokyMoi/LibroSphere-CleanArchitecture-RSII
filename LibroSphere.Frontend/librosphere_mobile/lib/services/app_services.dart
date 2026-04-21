import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/services/auth_api_service.dart';
import 'cart_service.dart';
import 'catalog_service.dart';
import 'library_service.dart';
import 'order_service.dart';
import 'session_storage_service.dart';
import 'notification_service.dart';
import 'wishlist_service.dart';

class AppServices {
  AppServices._({
    required this.apiClient,
    required this.authRepository,
    required this.catalog,
    required this.cart,
    required this.library,
    required this.notifications,
    required this.orders,
    required this.storage,
    required this.wishlist,
  });

  factory AppServices.fromPreferences(SharedPreferences prefs) {
    final storage = SessionStorageService(prefs);
    final httpClient = http.Client();
    final apiClient = ApiClient(httpClient);
    final authApiService = AuthApiService(apiClient);

    return AppServices._(
      apiClient: apiClient,
      authRepository: AuthRepository(authApiService),
      catalog: CatalogService(apiClient),
      cart: CartService(apiClient),
      library: LibraryService(apiClient),
      notifications: NotificationService(apiClient),
      orders: OrderService(apiClient),
      storage: storage,
      wishlist: WishlistService(apiClient),
    );
  }

  final ApiClient apiClient;
  final AuthRepository authRepository;
  final CatalogService catalog;
  final CartService cart;
  final LibraryService library;
  final NotificationService notifications;
  final OrderService orders;
  final SessionStorageService storage;
  final WishlistService wishlist;
}
