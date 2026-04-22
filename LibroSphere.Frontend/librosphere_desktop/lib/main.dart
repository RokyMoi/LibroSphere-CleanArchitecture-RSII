import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = AppInjection.createSessionViewModel();
  unawaited(session.initialize());

  runApp(LibroSphereDesktopApp(session: session));
}
