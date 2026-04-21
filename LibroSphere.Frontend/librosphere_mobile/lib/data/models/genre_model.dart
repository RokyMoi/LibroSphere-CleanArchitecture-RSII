import 'json_helpers.dart';

class GenreModel {
  GenreModel({required this.id, required this.name});

  final String id;
  final String name;

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: readString(json, ['id', 'Id', 'genreId', 'GenreId']),
      name: readString(json, ['name', 'Name']),
    );
  }
}
