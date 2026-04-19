import 'package:flutter/material.dart';

import '../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LibroSphereDesktopApp extends StatelessWidget {
  const LibroSphereDesktopApp({super.key, required this.session});

  final AdminSessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LibroSphere Desktop',
          theme: buildDesktopAppTheme(),
          home: AppRouter.resolveHome(session),
        );
      },
    );
  }
}
