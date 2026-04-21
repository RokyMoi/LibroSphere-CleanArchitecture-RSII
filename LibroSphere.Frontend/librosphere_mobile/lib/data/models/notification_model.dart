class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.isRead,
    required this.title,
    required this.text,
    required this.occurredOnUtc,
  });

  final String id;
  final bool isRead;
  final String title;
  final String text;
  final DateTime occurredOnUtc;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v is String) return v;
      }
      return '';
    }

    bool readBool(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v is bool) return v;
      }
      return false;
    }

    DateTime readDate(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v is String) {
          try {
            return DateTime.parse(v);
          } catch (_) {}
        }
      }
      return DateTime.now();
    }

    return NotificationModel(
      id: readString(const ['id', 'Id']),
      isRead: readBool(const ['isRead', 'IsRead']),
      title: readString(const ['title', 'Title']),
      text: readString(const ['text', 'Text']),
      occurredOnUtc: readDate(const ['occurredOnUtc', 'OccurredOnUtc']),
    );
  }
}
