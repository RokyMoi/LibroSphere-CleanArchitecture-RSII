import '../../../../core/utils/json_readers.dart';

class BookAssetsModel {
  BookAssetsModel({
    this.imageLink,
    this.pdfLink,
  });

  final String? imageLink;
  final String? pdfLink;

  factory BookAssetsModel.fromJson(Map<String, dynamic> json) {
    return BookAssetsModel(
      imageLink: readString(
        json,
        <String>['imageLink', 'ImageLink'],
        fallback: '',
      ),
      pdfLink: readString(
        json,
        <String>['pdfLink', 'PdfLink'],
        fallback: '',
      ),
    );
  }
}
