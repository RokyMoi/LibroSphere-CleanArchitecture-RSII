import '../../../../core/network/api_client.dart';
import '../models/orders_page_model.dart';

class OrdersApiService {
  OrdersApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<OrdersPageModel> getAllOrders({
    required String token,
    String? searchTerm,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final query = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _apiClient.getMap('/api/orders/all?$query', token: token);
    return OrdersPageModel.fromJson(response);
  }

  Future<void> refundOrder({
    required String token,
    required String orderId,
    double? amount,
    String? reason,
  }) async {
    final body = <String, dynamic>{};
    if (amount != null) {
      body['amount'] = amount;
    }
    if (reason != null) {
      body['reason'] = reason;
    }

    await _apiClient.postJson(
      '/api/orders/$orderId/refund',
      token: token,
      body: body.isEmpty ? null : body,
    );
  }
}
