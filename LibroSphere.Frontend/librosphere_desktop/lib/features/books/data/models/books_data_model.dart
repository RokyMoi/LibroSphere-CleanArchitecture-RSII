import 'admin_book_model.dart';

class BooksDataModel {
  BooksDataModel({
    required this.books,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<AdminBookModel> books;
  final int page;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
}
