import 'book_model.dart';
import 'paged_result.dart';

class HomeFeedModel {
  HomeFeedModel({required this.newest, required this.recommendations});

  final PagedResult<BookModel> newest;
  final List<BookModel> recommendations;
}
