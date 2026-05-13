import '../core/network/api_client.dart';
import '../data/models/order_model.dart';

class OrderService {
  OrderService(this._apiClient);

  final ApiClient _apiClient;

  Future<OrderModel> createOrder(
    String accessToken,
    String cartId,
    String paymentIntentId,
  ) {
    return _apiClient.createOrder(accessToken, cartId, paymentIntentId);
  }

  Future<OrderModel> waitForPaidOrder(
    String accessToken,
    String orderId, {
    int maxAttempts = 5,
  }) {
    return _apiClient.waitForPaidOrder(
      accessToken,
      orderId,
      maxAttempts: maxAttempts,
    );
  }
}
