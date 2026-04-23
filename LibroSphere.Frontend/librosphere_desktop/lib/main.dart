import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = AppInjection.createSessionViewModel();
  final languageController = AppInjection.createAdminLanguageController();
  unawaited(session.initialize());
  await languageController.initialize();

  runApp(
    LibroSphereDesktopApp(
      session: session,
      languageController: languageController,
    ),
  );
}
