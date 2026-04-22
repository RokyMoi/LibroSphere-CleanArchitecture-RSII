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

  bool get isPaid => _normalizeStatus(status) == 'paymentreceived';
  String get displayCurrency => currency.trim().isEmpty ? 'USD' : currency.trim();

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    final totalAmountValue = _readAny(
      json,
      const ['totalAmount', 'TotalAmount', 'price', 'Price'],
    );
    return AdminOrderModel(
      id: _readAny(json, const ['id', 'Id'])?.toString() ?? '',
      buyerEmail:
          _readAny(json, const ['buyerEmail', 'BuyerEmail'])?.toString() ?? '',
      status: _readAny(json, const ['status', 'Status'])?.toString() ?? 'Unknown',
      totalAmount: _parseDouble(totalAmountValue),
      currency: _parseCurrency(totalAmountValue, json),
      itemCount: _parseInt(
        _readAny(json, const ['itemCount', 'ItemCount']),
        fallback: itemsJson?.length ?? 0,
      ),
      createdOnUtc: DateTime.tryParse(
            _readAny(
                      json,
                      const ['createdOnUtc', 'CreatedOnUtc', 'orderDate', 'OrderDate'],
                    )
                    ?.toString() ??
                '',
          ) ??
          DateTime.now(),
      paymentIntentId:
          _readAny(json, const ['paymentIntentId', 'PaymentIntentId'])?.toString(),
      items: itemsJson?.map((e) => AdminOrderItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return _parseDouble(_readAny(map, const ['amount', 'Amount']));
    }
    return 0.0;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _parseCurrency(dynamic moneyValue, Map<String, dynamic> rootJson) {
    if (moneyValue is Map) {
      final map = Map<String, dynamic>.from(moneyValue);
      final directCode = _readAny(map, const ['code', 'Code']);
      if (directCode != null && directCode.toString().trim().isNotEmpty) {
        return directCode.toString().trim().toUpperCase();
      }

      final nestedCurrency = _readAny(map, const ['currency', 'Currency']);
      if (nestedCurrency is Map) {
        final nestedCode = _readAny(
          Map<String, dynamic>.from(nestedCurrency),
          const ['code', 'Code'],
        );
        if (nestedCode != null && nestedCode.toString().trim().isNotEmpty) {
          return nestedCode.toString().trim().toUpperCase();
        }
      }
    }

    final directCurrency = _readAny(rootJson, const ['currency', 'Currency']);
    if (directCurrency != null && directCurrency.toString().trim().isNotEmpty) {
      return directCurrency.toString().trim().toUpperCase();
    }

    return 'USD';
  }

  static dynamic _readAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
  }

  static String _normalizeStatus(String raw) =>
      raw.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
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
    final priceValue = AdminOrderModel._readAny(
      json,
      const ['price', 'Price', 'priceAtPurchase', 'PriceAtPurchase'],
    );
    return AdminOrderItemModel(
      bookId:
          AdminOrderModel._readAny(json, const ['bookId', 'BookId'])?.toString() ??
              '',
      title: AdminOrderModel._readAny(
                json,
                const ['title', 'Title', 'bookTitle', 'BookTitle'],
              )?.toString() ??
          'Unknown',
      price: AdminOrderModel._parseDouble(priceValue),
      currency: AdminOrderModel._parseCurrency(priceValue, json),
      quantity: AdminOrderModel._parseInt(
        AdminOrderModel._readAny(json, const ['quantity', 'Quantity']),
        fallback: 1,
      ),
      imageUrl:
          AdminOrderModel._readAny(json, const ['imageUrl', 'ImageUrl'])?.toString(),
    );
  }
}
