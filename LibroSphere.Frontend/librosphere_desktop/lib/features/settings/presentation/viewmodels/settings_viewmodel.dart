import 'package:flutter/material.dart';

import '../../../../core/error/result.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCreatingAdmin = false;
  bool get isCreatingAdmin => _isCreatingAdmin;

  String? _error;
  String? get error => _error;

  String? _createAdminError;
  String? get createAdminError => _createAdminError;

  String? _createAdminSuccess;
  String? get createAdminSuccess => _createAdminSuccess;

  String? _successMessage;
  String? get successMessage => _successMessage;

  SettingsViewModel(this._repository);

  void clearMessages() {
    _error = null;
    _successMessage = null;
    _createAdminError = null;
    _createAdminSuccess = null;
    notifyListeners();
  }

  Future<bool> createAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isCreatingAdmin = true;
    _createAdminError = null;
    _createAdminSuccess = null;
    notifyListeners();

    final result = await _repository.createAdmin(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    _isCreatingAdmin = false;

    if (result is Success<void>) {
      _createAdminSuccess = 'Admin nalog je uspjesno kreiran.';
      notifyListeners();
      return true;
    } else if (result is ErrorResult<void>) {
      _createAdminError = result.failure.toString();
      notifyListeners();
      return false;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _isLoading = true;
    clearMessages();
    notifyListeners();

    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );

    _isLoading = false;

    if (result is Success<void>) {
      _successMessage = 'Password changed successfully.';
      notifyListeners();
      return true;
    } else if (result is ErrorResult<void>) {
      _error = result.failure.toString();
      notifyListeners();
      return false;
    }
    return false;
  }
}
