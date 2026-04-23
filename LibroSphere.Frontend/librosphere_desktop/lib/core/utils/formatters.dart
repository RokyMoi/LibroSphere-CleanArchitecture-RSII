import '../localization/admin_language_controller.dart';

String formatAdminDate(
  String value, {
  AdminLanguage language = AdminLanguage.english,
}) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.replaceAll('T', ' ').replaceAll('Z', '');
  }

  final hasTime = value.contains('T') || value.contains(':');
  return _formatLocalizedDate(
    parsed.toLocal(),
    language: language,
    includeTime: hasTime,
  );
}

String formatAdminDateTime(
  DateTime? value, {
  AdminLanguage language = AdminLanguage.english,
}) {
  if (value == null) {
    return language.isEnglish ? 'Never' : 'Nikad';
  }

  return _formatLocalizedDate(
    value.toLocal(),
    language: language,
    includeTime: true,
  );
}

String formatCurrency(double amount, String currency) {
  final normalizedCurrency = currency.isEmpty ? 'USD' : currency;
  return '${amount.toStringAsFixed(2)} $normalizedCurrency';
}

String _formatLocalizedDate(
  DateTime value, {
  required AdminLanguage language,
  required bool includeTime,
}) {
  final day = value.day.toString().padLeft(2, '0');
  final month = _monthName(value.month, language);

  if (!includeTime) {
    return '$day $month ${value.year}';
  }

  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day $month ${value.year} $hour:$minute';
}

String _monthName(int month, AdminLanguage language) {
  if (language.isEnglish) {
    const english = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return english[month - 1];
  }

  const bosnian = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Maj',
    'Jun',
    'Jul',
    'Avg',
    'Sep',
    'Okt',
    'Nov',
    'Dec',
  ];
  return bosnian[month - 1];
}
