import 'package:flutter/material.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/common_widgets.dart';
import '../../data/models/register_request.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      return;
    }

    await widget.viewModel.register(
      RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  bool _validate() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _firstNameError = firstName.isEmpty ? 'First name is required.' : null;
      _lastNameError = lastName.isEmpty ? 'Last name is required.' : null;
      _emailError = email.isEmpty
          ? 'Email is required.'
          : (isValidEmail(email) ? null : 'Enter a valid email address.');
      _passwordError = password.isEmpty
          ? 'Password is required.'
          : (password.length >= 8
                ? null
                : 'Password must be at least 8 characters.');
    });

    if (_firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _passwordError == null) {
      widget.viewModel.clearError();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return AutofillGroup(
      child: ValueListenableBuilder<int>(
        valueListenable: viewModel.formState,
        builder: (context, _, child) {
          return Column(
            children: [
              RoundedInput(
                controller: _firstNameController,
                hint: 'Your First Name',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                errorText: _firstNameError,
                onChanged: (_) {
                  if (_firstNameError != null) {
                    setState(() => _firstNameError = null);
                  }
                  viewModel.clearError();
                },
              ),
              const SizedBox(height: 14),
              RoundedInput(
                controller: _lastNameController,
                hint: 'Your Last Name',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                errorText: _lastNameError,
                onChanged: (_) {
                  if (_lastNameError != null) {
                    setState(() => _lastNameError = null);
                  }
                  viewModel.clearError();
                },
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
              RoundedInput(
                controller: _passwordController,
                hint: 'Create a Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
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
                  label: viewModel.isSubmitting ? 'Creating...' : 'Register',
                  onPressed: viewModel.isSubmitting ? null : _submit,
                ),
              ),
              FormMessage(message: viewModel.errorMessage),
              const SizedBox(height: 12),
              TextButton(
                onPressed: viewModel.isSubmitting ? null : viewModel.showLogin,
                child: const Text(
                  'Already have an account? Login.',
                  style: TextStyle(color: brandBlueDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
