import 'book_model.dart';
import 'json_helpers.dart';

class LibraryEntry {
  LibraryEntry({
    required this.bookId,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.authorId,
    required this.authorName,
    required this.averageRating,
    required this.reviewCount,
    required this.genreIds,
    required this.genreNames,
    this.imageLink,
    this.pdfLink,
    this.purchasedAt,
  });

  final String bookId;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String authorId;
  final String authorName;
  final double averageRating;
  final int reviewCount;
  final List<String> genreIds;
  final List<String> genreNames;
  final String? imageLink;
  final String? pdfLink;
  final DateTime? purchasedAt;

  BookModel toBookModel() => BookModel(
    id: bookId,
    title: title,
    description: description,
    amount: amount,
    currency: currency,
    authorId: authorId,
    authorName: authorName,
    imageLink: imageLink,
    pdfLink: pdfLink,
    averageRating: averageRating,
    reviewCount: reviewCount,
  );

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
    bookId: readString(json, ['bookId', 'BookId']),
    title: readString(json, ['title', 'Title']),
    description: readString(json, ['description', 'Description']),
    amount: readDouble(json, ['amount', 'Amount']),
    currency: readString(json, ['currency', 'Currency'], fallback: 'USD'),
    authorId: readString(json, ['authorId', 'AuthorId']),
    authorName: readString(json, ['authorName', 'AuthorName']),
    averageRating: readDouble(json, ['averageRating', 'AverageRating']),
    reviewCount: readInt(json, ['reviewCount', 'ReviewCount']),
    genreIds: ((json['genreIds'] ?? json['GenreIds']) as List? ?? <dynamic>[])
        .map((value) => value.toString())
        .toList(),
    genreNames: ((json['genreNames'] ?? json['GenreNames']) as List? ?? <dynamic>[])
        .map((value) => value.toString())
        .toList(),
    imageLink: readNullableString(json, ['imageLink', 'ImageLink']),
    pdfLink: readNullableString(json, ['pdfLink', 'PdfLink']),
    purchasedAt: readDateTime(json, ['purchasedAt', 'PurchasedAt']),
  );
}
