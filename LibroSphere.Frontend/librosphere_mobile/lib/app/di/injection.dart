import '../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../../services/app_services.dart';

class AppInjection {
  static SessionViewModel createSessionViewModel() {
    return SessionViewModel(AppServices.create());
  }
}
