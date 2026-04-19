import 'json_helpers.dart';

class LibraryEntry {
  LibraryEntry({required this.bookId, required this.title, this.imageLink});

  final String bookId;
  final String title;
  final String? imageLink;

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
        bookId: readString(json, ['bookId', 'BookId']),
        title: readString(json, ['title', 'Title']),
        imageLink: readNullableString(json, ['imageLink', 'ImageLink']),
      );
}
