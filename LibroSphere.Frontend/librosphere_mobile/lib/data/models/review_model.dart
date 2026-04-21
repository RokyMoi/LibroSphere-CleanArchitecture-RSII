import 'json_helpers.dart';

class ReviewModel {
  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.userId,
    this.bookId,
    this.createdAt,
    this.userName,
    this.userProfilePictureUrl,
  });

  final String id;
  final int rating;
  final String comment;
  final String? userId;
  final String? bookId;
  final DateTime? createdAt;
  final String? userName;
  final String? userProfilePictureUrl;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: readString(json, ['id', 'Id']),
        rating: readInt(json, ['rating', 'Rating']),
        comment: readString(json, ['comment', 'Comment']),
        userId: readNullableString(json, ['userId', 'UserId']),
        bookId: readNullableString(json, ['bookId', 'BookId']),
        createdAt: readDateTime(json, ['createdAt', 'CreatedAt']),
        userName: readOptionalString(json, ['userName', 'UserName', 'reviewerName', 'ReviewerName']),
        userProfilePictureUrl: readOptionalString(json, ['userProfilePictureUrl', 'UserProfilePictureUrl', 'profilePictureUrl', 'ProfilePictureUrl']),
      );
}
