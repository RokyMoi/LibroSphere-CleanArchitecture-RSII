import 'package:flutter/material.dart';

import '../../../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.session,
  });

  final SessionViewModel session;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthViewModel _viewModel = AuthViewModel(widget.session);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 24.0;
              final cardWidth = constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: const [
                          BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 12)),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _viewModel,
                        builder: (context, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthHeader(isLoginMode: _viewModel.isLoginMode),
                              const SizedBox(height: 8),
                              Text(
                                _viewModel.isLoginMode
                                    ? 'Sign in to continue your reading journey.'
                                    : 'Create your account and continue where your reading journey begins.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                              ),
                              const SizedBox(height: 28),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _viewModel.isLoginMode
                                    ? LoginForm(
                                        key: const ValueKey('login'),
                                        viewModel: _viewModel,
                                      )
                                    : RegisterForm(
                                        key: const ValueKey('register'),
                                        viewModel: _viewModel,
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
