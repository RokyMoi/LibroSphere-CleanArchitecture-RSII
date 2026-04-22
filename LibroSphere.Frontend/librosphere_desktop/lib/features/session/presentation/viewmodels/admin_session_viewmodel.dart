import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../auth/data/models/auth_tokens_model.dart';
import '../../../auth/data/models/login_request.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/services/session_storage_service.dart';

class AdminSessionViewModel extends ChangeNotifier {
  AdminSessionViewModel(this._authRepository, this._storageService);

  final AuthRepository _authRepository;
  final SessionStorageService _storageService;

  bool isReady = false;
  AuthTokensModel? tokens;

  bool get isLoggedIn => tokens != null;
  String? get accessToken => tokens?.accessToken;

  Future<void> initialize() async {
    await _storageService.warmUp();
    tokens = await _storageService.restoreTokens();
    isReady = true;
    notifyListeners();
  }

  Future<Result<void>> login(String email, String password) async {
    final result = await _authRepository.login(
      LoginRequest(email: email, password: password),
    );

    switch (result) {
      case Success<AuthTokensModel>(value: final restoredTokens):
        tokens = restoredTokens;
        notifyListeners();
        unawaited(_storageService.persistTokens(restoredTokens));
        return const Success<void>(null);
      case ErrorResult<AuthTokensModel>(failure: final failure):
        return ErrorResult<void>(
          failure is Failure ? failure : Failure(message: failure.toString()),
        );
    }
  }

  Future<void> logout() async {
    tokens = null;
    await _storageService.clearSession();
    notifyListeners();
  }
}
