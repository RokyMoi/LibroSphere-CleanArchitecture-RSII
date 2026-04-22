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
  final ValueNotifier<bool> _modeState = ValueNotifier(true);
  final ValueNotifier<int> _formState = ValueNotifier(0);
  bool _isDisposed = false;

  bool isLoginMode = true;
  bool isSubmitting = false;
  String? errorMessage;
  ValueListenable<bool> get modeState => _modeState;
  ValueListenable<int> get formState => _formState;

  void showLogin() {
    if (_isDisposed) {
      return;
    }

    if (isLoginMode) {
      return;
    }

    isLoginMode = true;
    _modeState.value = true;
    errorMessage = null;
    _notifyFormState();
  }

  void showRegister() {
    if (_isDisposed) {
      return;
    }

    if (!isLoginMode) {
      return;
    }

    isLoginMode = false;
    _modeState.value = false;
    errorMessage = null;
    _notifyFormState();
  }

  void clearError() {
    if (_isDisposed) {
      return;
    }

    if (errorMessage == null) {
      return;
    }

    errorMessage = null;
    _notifyFormState();
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
    if (_isDisposed) {
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    _notifyFormState();

    bool success;
    try {
      success = await action();
    } catch (error) {
      if (_isDisposed) {
        return false;
      }

      errorMessage = error.toString();
      success = false;
    }

    if (_isDisposed) {
      return success;
    }

    isSubmitting = false;
    _notifyFormState();
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

  void _notifyFormState() {
    if (_isDisposed) {
      return;
    }

    _formState.value++;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _modeState.dispose();
    _formState.dispose();
    super.dispose();
  }
}

String normalizeAuthMessage(Object failure) {
  final rawMessage = failure is Failure ? failure.message : failure.toString();
  final message = rawMessage.trim();
  final normalizedMessage = message.toLowerCase();

  if (message.isEmpty ||
      message.contains('{Api.Code') ||
      message.contains('Api.Code')) {
    return 'Something went wrong. Please try again.';
  }

  if (normalizedMessage.contains('unable to reach librosphere api') ||
      normalizedMessage.contains('did not respond in time')) {
    return 'Unable to connect to the server. On the Android emulator, make sure the API is reachable at 10.0.2.2:8080.';
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
