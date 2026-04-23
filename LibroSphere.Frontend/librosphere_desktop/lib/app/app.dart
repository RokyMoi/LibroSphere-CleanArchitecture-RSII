import 'package:flutter/material.dart';

import '../core/localization/admin_language_controller.dart';
import '../core/localization/admin_language_scope.dart';
import '../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LibroSphereDesktopApp extends StatelessWidget {
  const LibroSphereDesktopApp({
    super.key,
    required this.session,
    required this.languageController,
  });

  final AdminSessionViewModel session;
  final AdminLanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([session, languageController]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LibroSphere Desktop',
          theme: buildDesktopAppTheme(),
          home: AdminLanguageScope(
            controller: languageController,
            child: AppRouter.resolveHome(session, languageController),
          ),
        );
      },
    );
  }
}
