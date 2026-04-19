import '../../../../core/utils/json_readers.dart';

class AdminAuthorModel {
  AdminAuthorModel({
    required this.id,
    required this.name,
    required this.biography,
  });

  final String id;
  final String name;
  final String biography;

  factory AdminAuthorModel.fromJson(Map<String, dynamic> json) {
    return AdminAuthorModel(
      id: readString(json, <String>['id', 'Id']),
      name: readString(json, <String>['name', 'Name']),
      biography: readString(json, <String>['biography', 'Biography']),
    );
  }
}
