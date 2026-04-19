import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final AdminSessionViewModel session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Container(
              width: 520,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: desktopPrimary,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/librosphere_logo.png',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'ADMIN LOGIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LoginForm(
                    emailController: _viewModel.emailController,
                    passwordController: _viewModel.passwordController,
                    isSubmitting: _viewModel.isSubmitting,
                    errorMessage: _viewModel.failure?.message,
                    onSubmit: () => _viewModel.submit(widget.session),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
