import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/app_constants.dart';
import 'features/session/presentation/viewmodels/session_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(_configureStripeInBackground());
  runApp(const _BootstrapApp());
}

Future<void> _configureStripeInBackground() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    return;
  }

  final stripeKey = resolveStripePublishableKey();
  if (stripeKey == null || stripeKey.isEmpty) {
    return;
  }

  Stripe.publishableKey = stripeKey;
  await Stripe.instance.applySettings();
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<SessionViewModel> _sessionFuture = _loadSession();

  Future<SessionViewModel> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final session = AppInjection.createSessionViewModel(prefs);
    unawaited(session.initialize());
    return session;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionViewModel>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return LibroSphereMobileApp(session: snapshot.data!);
      },
    );
  }
}
