import 'json_helpers.dart';

class WishlistItemModel {
  WishlistItemModel({required this.bookId, required this.title, this.imageLink});

  final String bookId;
  final String title;
  final String? imageLink;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) => WishlistItemModel(
        bookId: readString(json, ['bookId', 'BookId']),
        title: readString(json, ['title', 'Title']),
        imageLink: readNullableString(json, ['imageLink', 'ImageLink']),
      );
}
