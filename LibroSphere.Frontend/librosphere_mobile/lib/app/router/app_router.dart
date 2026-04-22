import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/data/models/auth_user_model.dart';
import '../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../../screens/home_shell.dart';

class AppRouter {
  static Widget resolveHome({
    required SessionViewModel session,
    required bool isReady,
    required AuthUserModel? currentUser,
  }) {
    if (!isReady) {
      return const _StartupPlaceholder();
    }

    if (currentUser == null) {
      return AuthPage(session: session);
    }

    return const HomeShell();
  }
}

class _StartupPlaceholder extends StatelessWidget {
  const _StartupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFF4F2F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      'assets/librosphere_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LibroSphere',
                    style: TextStyle(
                      color: brandBlueDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Restoring your reading session...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 170,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.68,
                      child: Container(
                        decoration: BoxDecoration(
                          color: brandBlueDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
