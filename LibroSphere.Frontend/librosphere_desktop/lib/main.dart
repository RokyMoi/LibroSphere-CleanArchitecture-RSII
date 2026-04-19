import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final session = AppInjection.createSessionViewModel(prefs);
  await session.initialize();

  runApp(LibroSphereDesktopApp(session: session));
}
