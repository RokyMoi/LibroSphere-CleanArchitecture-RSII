import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../session/presentation/viewmodels/admin_session_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isSubmitting = false;
  Failure? failure;

  Future<void> submit(AdminSessionViewModel session) async {
    final emailError = validateEmail(emailController.text);
    final passwordError = validateRequired(
      passwordController.text,
      'Password',
    );

    if (emailError != null || passwordError != null) {
      failure = Failure(message: emailError ?? passwordError!);
      notifyListeners();
      return;
    }

    isSubmitting = true;
    failure = null;
    notifyListeners();

    final result = await session.login(
      emailController.text.trim(),
      passwordController.text,
    );

    switch (result) {
      case Success<void>():
        failure = null;
      case ErrorResult<void>(failure: final error):
        failure = error is Failure
            ? error
            : Failure(message: error.toString());
    }

    isSubmitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
