import '../../../../core/utils/json_readers.dart';

class AdminGenreModel {
  AdminGenreModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory AdminGenreModel.fromJson(Map<String, dynamic> json) {
    return AdminGenreModel(
      id: readString(json, <String>['id', 'Id']),
      name: readString(json, <String>['name', 'Name']),
    );
  }
}
