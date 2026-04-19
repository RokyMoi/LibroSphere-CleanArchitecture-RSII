import '../core/network/api_client.dart';
import '../data/models/wishlist_model.dart';

class WishlistService {
  WishlistService(this._apiClient);

  final ApiClient _apiClient;

  Future<WishlistModel> getWishlist(String accessToken) {
    return _apiClient.getWishlist(accessToken);
  }

  Future<void> addToWishlist(String accessToken, String bookId) {
    return _apiClient.addWishlist(accessToken, bookId);
  }

  Future<void> removeFromWishlist(String accessToken, String bookId) {
    return _apiClient.removeWishlist(accessToken, bookId);
  }
}
