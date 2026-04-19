import 'dart:io';

import 'package:flutter/foundation.dart';

const configuredApiUrl = String.fromEnvironment('LIBROSPHERE_API_URL');

String resolveApiBaseUrl() {
  if (configuredApiUrl.isNotEmpty) {
    return configuredApiUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:8080';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }

  return 'http://localhost:8080';
}
