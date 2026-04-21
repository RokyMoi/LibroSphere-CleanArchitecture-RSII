class AdminOrderModel {
  const AdminOrderModel({
    required this.id,
    required this.buyerEmail,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.itemCount,
    required this.createdOnUtc,
    this.paymentIntentId,
    this.items = const [],
  });

  final String id;
  final String buyerEmail;
  final String status;
  final double totalAmount;
  final String currency;
  final int itemCount;
  final DateTime createdOnUtc;
  final String? paymentIntentId;
  final List<AdminOrderItemModel> items;

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    return AdminOrderModel(
      id: json['id']?.toString() ?? '',
      buyerEmail: json['buyerEmail']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      totalAmount: _parseDouble(json['totalAmount']),
      currency: json['currency']?.toString() ?? 'USD',
      itemCount: json['itemCount'] as int? ?? 0,
      createdOnUtc: DateTime.tryParse(json['createdOnUtc']?.toString() ?? '') ?? DateTime.now(),
      paymentIntentId: json['paymentIntentId']?.toString(),
      items: itemsJson?.map((e) => AdminOrderItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class AdminOrderItemModel {
  const AdminOrderItemModel({
    required this.bookId,
    required this.title,
    required this.price,
    required this.currency,
    required this.quantity,
    this.imageUrl,
  });

  final String bookId;
  final String title;
  final double price;
  final String currency;
  final int quantity;
  final String? imageUrl;

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderItemModel(
      bookId: json['bookId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      price: AdminOrderModel._parseDouble(json['price']),
      currency: json['currency']?.toString() ?? 'USD',
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
