import 'app_exception.dart';

class Failure {
  const Failure({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory Failure.fromException(AppException exception) {
    return Failure(
      message: exception.message,
      statusCode: exception.statusCode,
      code: exception.code,
    );
  }

  @override
  String toString() => message;
}
