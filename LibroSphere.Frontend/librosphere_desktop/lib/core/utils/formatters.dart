String formatAdminDate(String value) {
  return value.replaceAll('T', ' ').replaceAll('Z', '');
}

String formatAdminDateTime(DateTime? value) {
  if (value == null) {
    return 'Never';
  }

  final local = value.toLocal();
  final month = switch (local.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    _ => 'Dec',
  };

  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month ${local.year} $hour:$minute';
}

String formatCurrency(double amount, String currency) {
  final normalizedCurrency = currency.isEmpty ? 'USD' : currency;
  return '${amount.toStringAsFixed(2)} $normalizedCurrency';
}
