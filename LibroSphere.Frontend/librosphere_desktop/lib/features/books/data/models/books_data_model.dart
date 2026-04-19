import 'admin_author_model.dart';
import 'admin_book_model.dart';
import 'admin_genre_model.dart';

class BooksDataModel {
  BooksDataModel({
    required this.authors,
    required this.genres,
    required this.books,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<AdminAuthorModel> authors;
  final List<AdminGenreModel> genres;
  final List<AdminBookModel> books;
  final int page;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
}
