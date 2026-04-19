String? validateRequired(String value, String fieldName) {
  if (value.trim().isEmpty) {
    return '$fieldName is required.';
  }

  return null;
}

String? validateEmail(String value) {
  if (value.trim().isEmpty) {
    return 'Email is required.';
  }

  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(value.trim())) {
    return 'Enter a valid email address.';
  }

  return null;
}
