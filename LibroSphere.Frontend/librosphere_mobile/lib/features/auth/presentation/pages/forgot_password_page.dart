import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/common_widgets.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../session/presentation/viewmodels/session_viewmodel.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.session});

  final SessionViewModel session;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  bool _isSendingCode = false;
  bool _isResetting = false;
  String? _errorMessage;
  String? _successMessage;
  bool _codeSent = false;
  bool _resetComplete = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? 'Email is required.'
          : (isValidEmail(email) ? null : 'Enter a valid email address.');
      _errorMessage = null;
    });

    if (_emailError != null) return;

    setState(() => _isSendingCode = true);

    final result = await widget.session.requestPasswordReset(email);

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
      switch (result) {
        case Success<void>():
          _codeSent = true;
          _successMessage =
              'We sent a reset code to $email. Please check your inbox.';
        case ErrorResult<void>(failure: final f):
          _errorMessage = normalizeAuthMessage(f);
      }
    });
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _codeError = code.isEmpty ? 'Reset code is required.' : null;
      _passwordError = newPassword.isEmpty
          ? 'New password is required.'
          : (newPassword.length >= 8
                ? null
                : 'Password must be at least 8 characters.');
      _confirmError = confirmPassword.isEmpty
          ? 'Please confirm your new password.'
          : (confirmPassword != newPassword
                ? 'Passwords do not match.'
                : null);
      _errorMessage = null;
    });

    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }

    setState(() => _isResetting = true);

    final result = await widget.session.resetPasswordWithCode(
      email: _emailController.text.trim(),
      code: code,
      newPassword: newPassword,
    );

    if (!mounted) return;

    setState(() {
      _isResetting = false;
      switch (result) {
        case Success<void>():
          _resetComplete = true;
          _successMessage =
              'Your password has been changed successfully. You can now sign in.';
        case ErrorResult<void>(failure: final f):
          _errorMessage = normalizeAuthMessage(f);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brandBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: keyboardInset > 0 ? keyboardInset + 24 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_resetComplete) ...[
                  _buildSuccessView(),
                ] else if (!_codeSent) ...[
                  _buildEmailStep(),
                ] else ...[
                  _buildCodeStep(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forgot your password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: brandBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we will send you a password reset code.',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 32),
        RoundedInput(
          controller: _emailController,
          hint: 'Your email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),
        const SizedBox(height: 8),
        if (_errorMessage != null) ...[
          FormMessage(message: _errorMessage),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            label: _isSendingCode ? 'Sending...' : 'Send Code',
            onPressed: _isSendingCode ? null : _sendCode,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter the code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: brandBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _successMessage ?? '',
          style: const TextStyle(fontSize: 15, color: Color(0xFF1F8B4C)),
        ),
        const SizedBox(height: 24),
        RoundedInput(
          controller: _codeController,
          hint: '6-digit code',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          errorText: _codeError,
          onChanged: (_) {
            if (_codeError != null) {
              setState(() => _codeError = null);
            }
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        const SizedBox(height: 16),
        RoundedInput(
          controller: _newPasswordController,
          hint: 'New password',
          obscureText: true,
          textInputAction: TextInputAction.next,
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
        ),
        const SizedBox(height: 16),
        RoundedInput(
          controller: _confirmPasswordController,
          hint: 'Confirm new password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          errorText: _confirmError,
          onSubmitted: (_) => _resetPassword(),
          onChanged: (_) {
            if (_confirmError != null) {
              setState(() => _confirmError = null);
            }
          },
        ),
        const SizedBox(height: 8),
        if (_errorMessage != null) ...[
          FormMessage(message: _errorMessage),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            label: _isResetting ? 'Updating...' : 'Reset Password',
            onPressed: _isResetting ? null : _resetPassword,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _codeSent = false;
              _successMessage = null;
              _errorMessage = null;
            }),
            child: const Text(
              'Send a new code',
              style: TextStyle(color: brandBlueDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Color(0xFF1F8B4C),
        ),
        const SizedBox(height: 24),
        const Text(
          'Success!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: brandBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _successMessage ?? 'Your password has been changed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            label: 'Back to Sign In',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
