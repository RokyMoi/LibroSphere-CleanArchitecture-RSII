import 'book_model.dart';
import 'cart_item_input.dart';
import 'json_helpers.dart';

class ShoppingCartModel {
  ShoppingCartModel({
    required this.id,
    required this.userId,
    required this.items,
    this.clientSecret,
    this.paymentIntentId,
    this.books = const [],
  });

  final String id;
  final String userId;
  final List<CartItemInput> items;
  final String? clientSecret;
  final String? paymentIntentId;
  final List<BookModel> books;

  double get total => items.fold(0, (sum, item) => sum + item.amount);

  factory ShoppingCartModel.fromJson(Map<String, dynamic> json) {
    final items = (((json['items'] ?? json['Items']) as List?) ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((item) {
      final price = readMap(item, ['price', 'Price']);
      return CartItemInput(
        bookId: readString(item, ['bookId', 'BookId']),
        amount: readDouble(price, ['amount', 'Amount']),
        currencyCode: readString(price, ['currencyCode', 'CurrencyCode', 'currency', 'Currency'], fallback: 'USD'),
      );
    }).toList();
    final books = ((json['books'] ?? json['Books']) as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromJson)
        .toList();

    return ShoppingCartModel(
      id: readString(json, ['id', 'Id']),
      userId: readString(json, ['userId', 'UserId']),
      clientSecret: readNullableString(json, ['clientSecret', 'ClientSecret']),
      paymentIntentId: readNullableString(json, ['paymentIntentId', 'PaymentIntentId']),
      items: items,
      books: books,
    );
  }
}
