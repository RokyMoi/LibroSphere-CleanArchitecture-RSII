import 'json_helpers.dart';

class ReviewModel {
  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.userId,
    this.bookId,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String? userId;
  final String? bookId;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: readString(json, ['id', 'Id']),
        rating: readInt(json, ['rating', 'Rating']),
        comment: readString(json, ['comment', 'Comment']),
        userId: readNullableString(json, ['userId', 'UserId']),
        bookId: readNullableString(json, ['bookId', 'BookId']),
        createdAt: readDateTime(json, ['createdAt', 'CreatedAt']),
      );
}
