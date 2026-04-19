import '../../../../core/utils/json_readers.dart';

class AdminBookModel {
  AdminBookModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.genreIds,
    required this.amount,
    required this.currency,
    this.imageLink,
    this.pdfLink,
  });

  final String id;
  final String title;
  final String description;
  final String authorId;
  final List<String> genreIds;
  final double amount;
  final String currency;
  final String? imageLink;
  final String? pdfLink;

  factory AdminBookModel.fromJson(Map<String, dynamic> json) {
    return AdminBookModel(
      id: readString(json, <String>['bookId', 'BookId']),
      title: readString(json, <String>['title', 'Title']),
      description: readString(json, <String>['description', 'Description']),
      authorId: readString(json, <String>['authorId', 'AuthorId']),
      genreIds: _readStringList(json, 'genreIds', 'GenreIds'),
      amount: readDouble(json, <String>['amount', 'Amount']),
      currency: readString(
        json,
        <String>['currency', 'Currency'],
        fallback: 'USD',
      ),
      imageLink: readNullableString(
        json,
        <String>['imageLink', 'ImageLink'],
      ),
      pdfLink: readNullableString(
        json,
        <String>['pdfLink', 'PdfLink'],
      ),
    );
  }

  static List<String> _readStringList(
    Map<String, dynamic> json,
    String camelKey,
    String pascalKey,
  ) {
    final value = json[camelKey] ?? json[pascalKey];
    if (value is! List) {
      return const <String>[];
    }

    return value
        .where((item) => item != null)
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
