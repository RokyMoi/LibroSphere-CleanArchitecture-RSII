import 'package:flutter/material.dart';

import '../features/auth/data/models/auth_user_model.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../features/session/presentation/session_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LibroSphereMobileApp extends StatelessWidget {
  const LibroSphereMobileApp({super.key, required this.session});

  final SessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LibroSphere',
      theme: buildAppTheme(),
      home: SessionScope(
        session: session,
        child: const _SessionHome(),
      ),
    );
  }
}

class _SessionHome extends StatelessWidget {
  const _SessionHome();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.read(context);

    return ValueListenableBuilder<bool>(
      valueListenable: session.readyState,
      builder: (context, isReady, _) {
        if (!isReady) {
          return AppRouter.resolveHome(
            session: session,
            isReady: false,
            currentUser: null,
          );
        }

        return ValueListenableBuilder<AuthUserModel?>(
          valueListenable: session.profileState,
          builder: (context, currentUser, child) {
            return AppRouter.resolveHome(
              session: session,
              isReady: true,
              currentUser: currentUser,
            );
          },
        );
      },
    );
  }
}
