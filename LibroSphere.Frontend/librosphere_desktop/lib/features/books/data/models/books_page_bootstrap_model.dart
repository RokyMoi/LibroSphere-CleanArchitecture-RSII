import '../../../genres/data/models/admin_genre_model.dart';
import 'admin_author_model.dart';
import 'books_data_model.dart';

class BooksPageBootstrapModel {
  BooksPageBootstrapModel({
    required this.booksPage,
    required this.authors,
    required this.genres,
  });

  final BooksDataModel booksPage;
  final List<AdminAuthorModel> authors;
  final List<AdminGenreModel> genres;
}
