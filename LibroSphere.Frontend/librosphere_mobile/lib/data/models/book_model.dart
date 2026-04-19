import 'json_helpers.dart';

class BookModel {
  BookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.authorId,
    this.imageLink,
    this.pdfLink,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String authorId;
  final String? imageLink;
  final String? pdfLink;

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        id: readString(json, ['bookId', 'BookId', 'id', 'Id']),
        title: readString(json, ['title', 'Title']),
        description: readString(json, ['description', 'Description']),
        amount: readDouble(json, ['amount', 'Amount']),
        currency: readString(json, ['currency', 'Currency'], fallback: 'USD'),
        authorId: readString(json, ['authorId', 'AuthorId']),
        imageLink: readNullableString(json, ['imageLink', 'ImageLink']),
        pdfLink: readNullableString(json, ['pdfLink', 'PdfLink']),
      );
}
