import '../../../../data/models/json_helpers.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePictureUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePictureUrl;

  String get fullName => '$firstName $lastName';

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: readString(json, ['id', 'Id']),
        firstName: readString(json, ['firstName', 'FirstName']),
        lastName: readString(json, ['lastName', 'LastName']),
        email: readString(json, ['email', 'Email']),
        profilePictureUrl: readOptionalString(json, ['profilePictureUrl', 'ProfilePictureUrl']),
      );

  AuthUserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? profilePictureUrl,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
