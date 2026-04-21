class ApiConstants {
  static const String configuredApiUrl = String.fromEnvironment('LIBROSPHERE_API_URL');
  static String get baseUrl => configuredApiUrl.isNotEmpty ? configuredApiUrl : 'http://localhost:8080';
  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration uploadRequestTimeout = Duration(minutes: 2);
}
