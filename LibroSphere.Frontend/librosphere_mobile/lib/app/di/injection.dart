import 'package:shared_preferences/shared_preferences.dart';

import '../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../../services/app_services.dart';

class AppInjection {
  static SessionViewModel createSessionViewModel(SharedPreferences prefs) {
    return SessionViewModel(AppServices.fromPreferences(prefs));
  }
}
