class CartItemInput {
  CartItemInput({required this.bookId, required this.amount, required this.currencyCode});

  final String bookId;
  final double amount;
  final String currencyCode;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'price': {'amount': amount, 'currencyCode': currencyCode},
      };
}
