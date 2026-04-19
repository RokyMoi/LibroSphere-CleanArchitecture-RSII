import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/app_constants.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    var stripeKey = resolveStripePublishableKey();
    if (stripeKey == null) {
      try {
        stripeKey = await ApiClient().getStripePublishableKey();
        setRuntimeStripePublishableKey(stripeKey);
      } catch (_) {
        // Checkout screen will explain missing Stripe configuration if this stays unavailable.
      }
    }

    if (stripeKey != null) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final session = AppInjection.createSessionViewModel(prefs);
  await session.initialize();

  runApp(LibroSphereMobileApp(session: session));
}
