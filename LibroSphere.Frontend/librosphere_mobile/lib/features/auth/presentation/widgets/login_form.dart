import 'package:flutter/material.dart';
import '../../../../core/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/common_widgets.dart';
import '../../data/models/login_request.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      return;
    }

    await widget.viewModel.login(
      LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty
          ? 'Email is required.'
          : (isValidEmail(email) ? null : 'Enter a valid email address.');
      _passwordError = password.isEmpty ? 'Password is required.' : null;
    });

    if (_emailError == null && _passwordError == null) {
      widget.viewModel.clearError();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return AutofillGroup(
      child: Column(
        children: [
          RoundedInput(
            controller: _emailController,
            hint: 'Your Email Address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            enableSuggestions: false,
            autocorrect: false,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
              viewModel.clearError();
            },
          ),
          const SizedBox(height: 16),
          RoundedInput(
            controller: _passwordController,
            hint: 'Your Password',
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enableSuggestions: false,
            autocorrect: false,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
              viewModel.clearError();
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryPillButton(
              label: viewModel.isSubmitting ? 'Signing In...' : 'Login',
              onPressed: viewModel.isSubmitting ? null : _submit,
            ),
          ),
          FormMessage(message: viewModel.errorMessage),
          const SizedBox(height: 12),
          TextButton(
            onPressed: viewModel.isSubmitting ? null : viewModel.showRegister,
            child: const Text(
              'Need an account? Register here.',
              style: TextStyle(color: brandBlueDark),
            ),
          ),
        ],
      ),
    );
  }
}
