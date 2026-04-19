import 'dart:ui';

const brandBlue = Color(0xFF1F8FFF);
const brandBlueDark = Color(0xFF1677DB);
const pageBackground = Color(0xFFF5F5F5);
const configuredStripePublishableKey = String.fromEnvironment('LIBROSPHERE_STRIPE_PUBLISHABLE_KEY');
const configuredStripeMerchantCountryCode = String.fromEnvironment('LIBROSPHERE_STRIPE_COUNTRY_CODE');
String? _runtimeStripePublishableKey;

String? resolveStripePublishableKey() {
  final value = configuredStripePublishableKey.trim();
  if (value.isNotEmpty) {
    return value;
  }

  final runtimeValue = _runtimeStripePublishableKey?.trim();
  return runtimeValue == null || runtimeValue.isEmpty ? null : runtimeValue;
}

String resolveStripeMerchantCountryCode() {
  final configured = configuredStripeMerchantCountryCode.trim().toUpperCase();
  if (configured.length == 2) {
    return configured;
  }

  final localeCountryCode = PlatformDispatcher.instance.locale.countryCode?.trim().toUpperCase();
  if (localeCountryCode != null && localeCountryCode.length == 2) {
    return localeCountryCode;
  }

  return 'US';
}

void setRuntimeStripePublishableKey(String? value) {
  final normalized = value?.trim();
  _runtimeStripePublishableKey = (normalized == null || normalized.isEmpty) ? null : normalized;
}
