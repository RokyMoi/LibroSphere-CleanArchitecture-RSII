import 'package:flutter/material.dart';

import '../../../../core/app_constants.dart';
import '../../../../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.session});

  final SessionViewModel session;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthViewModel _viewModel = AuthViewModel(widget.session);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: pageBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final horizontalPadding = compact ? 14.0 : 24.0;
              final verticalPadding = compact ? 18.0 : 24.0;
              final cardWidth = constraints.maxWidth < 420
                  ? constraints.maxWidth
                  : 420.0;
              final cardPadding = compact
                  ? const EdgeInsets.fromLTRB(20, 22, 20, 18)
                  : const EdgeInsets.fromLTRB(24, 28, 24, 22);

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8FBFF), Color(0xFFF4F2F8)],
                  ),
                ),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset > 0 ? 12 : 0),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - (verticalPadding * 2),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardWidth),
                            child: Container(
                              width: double.infinity,
                              padding: cardPadding,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                compact ? 30 : 36,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _viewModel.modeState,
                              builder: (context, isLoginMode, _) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AuthHeader(isLoginMode: isLoginMode),
                                    SizedBox(height: compact ? 6 : 8),
                                    Text(
                                      isLoginMode
                                          ? 'Sign in to continue your reading journey.'
                                          : 'Create your account and continue where your reading journey begins.',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: compact ? 14 : 15,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 22 : 28),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: isLoginMode
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
