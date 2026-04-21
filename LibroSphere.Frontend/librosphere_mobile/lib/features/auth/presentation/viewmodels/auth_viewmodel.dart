import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../../session/presentation/viewmodels/session_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._session);

  final SessionViewModel _session;
  SessionViewModel get session => _session;

  bool isLoginMode = true;
  bool isSubmitting = false;
  String? errorMessage;

  void showLogin() {
    if (isLoginMode) {
      return;
    }

    isLoginMode = true;
    errorMessage = null;
    notifyListeners();
  }

  void showRegister() {
    if (!isLoginMode) {
      return;
    }

    isLoginMode = false;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) {
      return;
    }

    errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(LoginRequest request) async {
    return _run(() async {
      final result = await _session.login(request.email, request.password);
      return _handleResult(result);
    });
  }

  Future<bool> register(RegisterRequest request) async {
    return _run(() async {
      final result = await _session.register(
        firstName: request.firstName,
        lastName: request.lastName,
        email: request.email,
        password: request.password,
      );
      return _handleResult(result);
    });
  }

  Future<bool> _run(Future<bool> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    bool success;
    try {
      success = await action();
    } catch (error) {
      errorMessage = error.toString();
      success = false;
    }

    isSubmitting = false;
    notifyListeners();
    return success;
  }

  bool _handleResult(Result<void> result) {
    switch (result) {
      case Success<void>():
        return true;
      case ErrorResult<void>(failure: final failure):
        errorMessage = _mapFailure(failure);
        return false;
    }
  }

  String _mapFailure(Object failure) {
    return normalizeAuthMessage(failure);
  }
}

String normalizeAuthMessage(Object failure) {
  final rawMessage = failure is Failure ? failure.message : failure.toString();
  final message = rawMessage.trim();

  if (message.isEmpty ||
      message.contains('{Api.Code') ||
      message.contains('Api.Code')) {
    return 'Something went wrong. Please try again.';
  }

  switch (message) {
    case 'Pogresili ste sifru ili email.':
      return 'Incorrect email or password.';
    case 'Email je obavezan.':
      return 'Email is required.';
    case 'Sva polja su obavezna.':
      return 'All fields are required.';
    case 'Kod je pogresan ili je istekao.':
      return 'The reset code is invalid or has expired.';
    case 'Lozinka je uspjesno promijenjena.':
      return 'Your password has been changed successfully.';
    default:
      return message;
  }
}
