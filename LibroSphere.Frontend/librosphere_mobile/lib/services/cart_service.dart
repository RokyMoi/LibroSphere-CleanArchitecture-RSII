import '../core/network/api_client.dart';
import '../data/models/cart_item_input.dart';
import '../data/models/shopping_cart_model.dart';

class CartService {
  CartService(this._apiClient);

  final ApiClient _apiClient;

  Future<ShoppingCartModel> getCart(String accessToken, String cartId) {
    return _apiClient.getCart(accessToken, cartId);
  }

  Future<ShoppingCartModel> upsertCart({
    required String accessToken,
    required String cartId,
    required String userId,
    required List<CartItemInput> items,
    String? clientSecret,
    String? paymentIntentId,
  }) {
    return _apiClient.upsertCart(
      accessToken: accessToken,
      cartId: cartId,
      userId: userId,
      items: items,
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
    );
  }

  Future<void> deleteCart(String accessToken, String cartId) {
    return _apiClient.deleteCart(accessToken, cartId);
  }

  Future<ShoppingCartModel> createPaymentIntent(String accessToken, String cartId) {
    return _apiClient.createPaymentIntent(accessToken, cartId);
  }
}
