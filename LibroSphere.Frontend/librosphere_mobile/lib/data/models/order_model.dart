import 'json_helpers.dart';
import 'order_status.dart';

class OrderModel {
  OrderModel({required this.id, required this.status, this.clientSecret});

  final String id;
  final OrderStatus status;
  final String? clientSecret;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: readString(json, ['id', 'Id']),
        status: parseOrderStatus(json['status'] ?? json['Status']),
        clientSecret: readNullableString(json, ['clientSecret', 'ClientSecret']),
      );
}
