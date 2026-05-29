import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/orders_page_model.dart';
import '../services/orders_api_service.dart';

class OrdersRepository {
  OrdersRepository(this._apiService);

  final OrdersApiService _apiService;

  Future<Result<OrdersPageModel>> getAllOrders({
    required String token,
    String? searchTerm,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _apiService.getAllOrders(
        token: token,
        searchTerm: searchTerm,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Success(result);
    } catch (e) {
      return ErrorResult(Failure(message: 'Orders.LoadFailed: $e'));
    }
  }

  Future<Result<void>> approveRefund({
    required String token,
    required String orderId,
  }) async {
    try {
      await _apiService.approveRefund(token: token, orderId: orderId);
      return const Success(null);
    } catch (e) {
      return ErrorResult(Failure(message: 'Refund.ApproveFailed: $e'));
    }
  }

  Future<Result<void>> rejectRefund({
    required String token,
    required String orderId,
    String? reason,
  }) async {
    try {
      await _apiService.rejectRefund(token: token, orderId: orderId, reason: reason);
      return const Success(null);
    } catch (e) {
      return ErrorResult(Failure(message: 'Refund.RejectFailed: $e'));
    }
  }
}
