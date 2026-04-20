import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/users_page_model.dart';
import '../../data/repositories/users_repository.dart';

class UsersViewModel extends ChangeNotifier {
  UsersViewModel(this._repository, this._token);

  final UsersRepository _repository;
  final String _token;
  final int pageSize = 12;
  bool _hasLoaded = false;

  bool isLoading = true;
  String? deletingUserId;
  Failure? failure;
  List<AdminUserModel> users = <AdminUserModel>[];
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  bool hasPreviousPage = false;
  bool hasNextPage = false;

  Future<void> ensureLoaded() {
    if (_hasLoaded) {
      return Future<void>.value();
    }

    return load();
  }

  Future<void> load({int? page}) async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final targetPage = page ?? currentPage;
    final result = await _repository.getUsers(
      _token,
      page: targetPage,
      pageSize: pageSize,
    );

    switch (result) {
      case Success<UsersPageModel>(value: final loadedPage):
        users = loadedPage.items;
        currentPage = loadedPage.page;
        totalPages = loadedPage.totalPages;
        totalCount = loadedPage.totalCount;
        hasPreviousPage = loadedPage.hasPreviousPage;
        hasNextPage = loadedPage.hasNextPage;
        _hasLoaded = true;
      case ErrorResult<UsersPageModel>(failure: final error):
        failure = error is Failure
            ? error
            : Failure(message: error.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (!hasNextPage || isLoading) {
      return;
    }

    await load(page: currentPage + 1);
  }

  Future<void> loadPreviousPage() async {
    if (!hasPreviousPage || isLoading) {
      return;
    }

    await load(page: currentPage - 1);
  }

  Future<Result<void>> deleteUser(String userId) async {
    failure = null;
    deletingUserId = userId;
    notifyListeners();

    final result = await _repository.deleteUser(_token, userId);

    switch (result) {
      case Success<void>():
        final targetPage = users.length == 1 && currentPage > 1
            ? currentPage - 1
            : currentPage;
        await load(page: targetPage);
        deletingUserId = null;
        notifyListeners();
        if (failure != null) {
          return ErrorResult<void>(failure!);
        }
        return const Success<void>(null);
      case ErrorResult<void>(failure: final error):
        deletingUserId = null;
        notifyListeners();
        return ErrorResult<void>(
          error is Failure ? error : Failure(message: error.toString()),
        );
    }
  }
}
