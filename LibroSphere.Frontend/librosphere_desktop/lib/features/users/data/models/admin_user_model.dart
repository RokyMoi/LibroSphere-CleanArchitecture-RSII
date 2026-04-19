import '../../../../core/utils/json_readers.dart';

class AdminUserModel {
  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.dateRegistered,
    required this.lastLogin,
    required this.isActive,
  });

  final String id;
  final String name;
  final String email;
  final String dateRegistered;
  final DateTime? lastLogin;
  final bool isActive;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: readString(json, <String>['id', 'Id']),
      name:
          '${readString(json, <String>['firstName', 'FirstName'])} ${readString(json, <String>['lastName', 'LastName'])}'
              .trim(),
      email: readString(json, <String>['email', 'Email']),
      dateRegistered: readString(
        json,
        <String>['dateRegistered', 'DateRegistered'],
      ),
      lastLogin: readDateTime(json, <String>['lastLogin', 'LastLogin']),
      isActive: readBool(json, <String>['isActive', 'IsActive']),
    );
  }
}
