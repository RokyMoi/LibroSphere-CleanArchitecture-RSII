String readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return value.toString();
  }

  return fallback;
}

String? readNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = readString(json, keys);
  return value.isEmpty ? null : value;
}

int readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return fallback;
}

double readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
  }

  return 0;
}

bool readBool(Map<String, dynamic> json, List<String> keys, {bool fallback = false}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
  }

  return fallback;
}

DateTime? readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
  }

  return null;
}

List<Map<String, dynamic>> readItems(Map<String, dynamic> json) {
  final items = json['items'];
  if (items is List) {
    return items.whereType<Map<String, dynamic>>().toList();
  }

  return <Map<String, dynamic>>[];
}
