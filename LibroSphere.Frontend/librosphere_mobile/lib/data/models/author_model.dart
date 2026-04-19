import 'json_helpers.dart';

class AuthorModel {
  AuthorModel({required this.id, required this.name});

  final String id;
  final String name;

  factory AuthorModel.fromJson(Map<String, dynamic> json) => AuthorModel(
        id: readString(json, ['id', 'Id']),
        name: readString(json, ['name', 'Name']),
      );
}
