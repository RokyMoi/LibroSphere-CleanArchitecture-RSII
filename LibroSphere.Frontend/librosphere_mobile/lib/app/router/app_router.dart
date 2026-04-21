import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/data/models/auth_user_model.dart';
import '../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../../screens/home_shell.dart';
import '../../widgets/common_widgets.dart';

class AppRouter {
  static Widget resolveHome({
    required SessionViewModel session,
    required bool isReady,
    required AuthUserModel? currentUser,
  }) {
    if (!isReady) {
      return const Scaffold(
        body: CenteredLoadingIndicator(),
      );
    }

    if (currentUser == null) {
      return AuthPage(session: session);
    }

    return const HomeShell();
  }
}
