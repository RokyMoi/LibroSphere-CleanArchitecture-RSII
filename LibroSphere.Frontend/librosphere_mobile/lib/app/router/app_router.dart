import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../../screens/home_shell.dart';
import '../../widgets/common_widgets.dart';

class AppRouter {
  static Widget resolveHome(SessionViewModel session) {
    if (!session.isReady) {
      return const Scaffold(
        body: CenteredLoadingIndicator(),
      );
    }

    if (session.currentUser == null) {
      return AuthPage(session: session);
    }

    return const HomeShell();
  }
}
