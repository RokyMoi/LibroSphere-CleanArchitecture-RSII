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

  Future<void> approveRefund(
      {required String token, required String orderId}) async {
    await _apiClient.postJson(
      '/api/orders/$orderId/refund',
      token: token,
      body: {'reason': 'Approved by admin'},
    );
  }

  Future<void> rejectRefund(
      {required String token, required String orderId, String? reason}) async {
    await _apiClient.postJson(
      '/api/orders/$orderId/refund/reject',
      token: token,
      body: {'reason': reason ?? 'Rejected by admin'},
    );
  }
}
