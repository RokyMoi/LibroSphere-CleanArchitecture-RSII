import 'package:flutter/material.dart';

import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../features/session/presentation/session_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LibroSphereMobileApp extends StatelessWidget {
  const LibroSphereMobileApp({super.key, required this.session});

  final SessionViewModel session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LibroSphere',
          theme: buildAppTheme(),
          home: SessionScope(
            session: session,
            child: AppRouter.resolveHome(session),
          ),
        );
      },
    );
  }
}
