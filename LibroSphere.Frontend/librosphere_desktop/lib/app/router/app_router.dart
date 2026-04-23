import 'package:flutter/material.dart';

import '../../core/localization/admin_language_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../features/shell/presentation/pages/admin_shell_page.dart';

class AppRouter {
  static Widget resolveHome(
    AdminSessionViewModel session,
    AdminLanguageController languageController,
  ) {
    if (!session.isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return session.isLoggedIn
        ? AdminShellPage(
            session: session,
            languageController: languageController,
          )
        : LoginPage(session: session);
  }
}
