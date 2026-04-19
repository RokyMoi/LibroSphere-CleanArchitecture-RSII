import '../../../../core/utils/json_readers.dart';

class AnalyticsActivityModel {
  AnalyticsActivityModel({
    required this.entityName,
    required this.action,
    required this.description,
    required this.occurredOnUtc,
  });

  final String entityName;
  final String action;
  final String description;
  final DateTime? occurredOnUtc;

  factory AnalyticsActivityModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsActivityModel(
      entityName: readString(json, <String>['entityName', 'EntityName']),
      action: readString(json, <String>['action', 'Action']),
      description: readString(
        json,
        <String>['description', 'Description'],
      ),
      occurredOnUtc: readDateTime(
        json,
        <String>['occurredOnUtc', 'OccurredOnUtc'],
      ),
    );
  }
}
