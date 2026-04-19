import '../../../../data/models/json_helpers.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName';

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: readString(json, ['id', 'Id']),
        firstName: readString(json, ['firstName', 'FirstName']),
        lastName: readString(json, ['lastName', 'LastName']),
        email: readString(json, ['email', 'Email']),
      );
}
