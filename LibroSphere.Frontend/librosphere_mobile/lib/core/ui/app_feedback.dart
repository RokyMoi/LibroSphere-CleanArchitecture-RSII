import 'package:flutter/material.dart';

import '../error/app_exception.dart';
import '../error/failure.dart';

String formatErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  if (error is AppException) {
    return error.message;
  }
  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}

void _showSnackBar(
  BuildContext context,
  String message, {
  required Color backgroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorSnackBar(BuildContext context, Object error) {
  _showSnackBar(
    context,
    formatErrorMessage(error),
    backgroundColor: const Color(0xFFB42318),
  );
}

void showMessageSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message,
    backgroundColor: const Color(0xFF475467),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message,
    backgroundColor: const Color(0xFF027A48),
  );
}

void showDestructiveSnackBar(BuildContext context, String message) {
  _showSnackBar(
    context,
    message,
    backgroundColor: const Color(0xFFB42318),
  );
}
