import 'json_helpers.dart';

class BookModel {
  BookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.authorId,
    required this.authorName,
    this.imageLink,
    this.pdfLink,
    this.averageRating = 0,
    this.reviewCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String authorId;
  final String authorName;
  final String? imageLink;
  final String? pdfLink;
  final double averageRating;
  final int reviewCount;

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
    id: readString(json, ['bookId', 'BookId', 'id', 'Id']),
    title: readString(json, ['title', 'Title']),
    description: readString(json, ['description', 'Description']),
    amount: readDouble(json, ['amount', 'Amount']),
    currency: readString(json, ['currency', 'Currency'], fallback: 'USD'),
    authorId: readString(json, ['authorId', 'AuthorId']),
    authorName: readString(
      json,
      ['authorName', 'AuthorName'],
      fallback: '',
    ),
    imageLink: readNullableString(json, ['imageLink', 'ImageLink']),
    pdfLink: readNullableString(json, ['pdfLink', 'PdfLink']),
    averageRating: readDouble(json, ['averageRating', 'AverageRating']),
    reviewCount: readInt(json, ['reviewCount', 'ReviewCount']),
  );
}
