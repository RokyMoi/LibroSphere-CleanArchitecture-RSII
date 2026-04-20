import 'admin_author_model.dart';
import '../../../genres/data/models/admin_genre_model.dart';

class BookLookupData {
  const BookLookupData({
    required this.authors,
    required this.genres,
  });

  final List<AdminAuthorModel> authors;
  final List<AdminGenreModel> genres;
}
