import '../../../../core/utils/json_readers.dart';

class AdminNewsModel {
  AdminNewsModel({
    required this.id,
    required this.title,
    required this.text,
    required this.imageUrl,
    required this.createdOnUtc,
  });

  final String id;
  final String title;
  final String text;
  final String imageUrl;
  final DateTime? createdOnUtc;

  factory AdminNewsModel.fromJson(Map<String, dynamic> json) {
    return AdminNewsModel(
      id: readString(json, <String>['id', 'newsId', 'NewsId', 'Id']),
      title: readString(json, <String>['title', 'Title']),
      text: readString(json, <String>['text', 'Text', 'content', 'Content']),
      imageUrl: readString(json, <String>['imageUrl', 'ImageUrl'], fallback: ''),
      createdOnUtc: readDateTime(json, <String>['createdOnUtc', 'CreatedOnUtc']),
    );
  }
}
