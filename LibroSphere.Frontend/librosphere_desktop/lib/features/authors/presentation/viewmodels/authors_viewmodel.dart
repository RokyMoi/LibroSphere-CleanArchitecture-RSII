import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../../data/repositories/authors_repository.dart';

class AuthorsViewModel extends ChangeNotifier {
  AuthorsViewModel(
    this._repository,
    this._token, {
    Future<void> Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged;

  final AuthorsRepository _repository;
  final String _token;
  final Future<void> Function()? _onDataChanged;
  final int pageSize = 10;
  bool _hasLoaded = false;

  bool isLoading = true;
  bool isSaving = false;
  String? deletingAuthorId;
  Failure? failure;
  List<AdminAuthorModel> authors = <AdminAuthorModel>[];
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
    final result = await _repository.getAuthors(
      _token,
      page: targetPage,
      pageSize: pageSize,
    );

    switch (result) {
      case Success(value: final loadedPage):
        authors = loadedPage.items;
        currentPage = loadedPage.page;
        totalPages = loadedPage.totalPages;
        totalCount = loadedPage.totalCount;
        hasPreviousPage = loadedPage.hasPreviousPage;
        hasNextPage = loadedPage.hasNextPage;
        _hasLoaded = true;
      case ErrorResult(failure: final error):
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

  Future<Result<void>> saveAuthor({
    required AdminAuthorModel? existingAuthor,
    required String name,
    required String biography,
  }) async {
    isSaving = true;
    notifyListeners();

    final result = await _repository.saveAuthor(
      token: _token,
      existingAuthor: existingAuthor,
      name: name,
      biography: biography,
    );

    if (result is Success<void>) {
      await load();
      await _notifyDataChanged();
    } else {
      isSaving = false;
      notifyListeners();
    }

    isSaving = false;
    notifyListeners();
    return result;
  }

  Future<Result<void>> deleteAuthor(AdminAuthorModel author) async {
    deletingAuthorId = author.id;
    notifyListeners();

    final result = await _repository.deleteAuthor(
      token: _token,
      author: author,
    );

    deletingAuthorId = null;

    if (result is Success<void>) {
      final nextPage = authors.length == 1 && currentPage > 1
          ? currentPage - 1
          : currentPage;
      await load(page: nextPage);
      await _notifyDataChanged();
    } else {
      notifyListeners();
    }

    return result;
  }

  Future<void> _notifyDataChanged() async {
    try {
      await _onDataChanged?.call();
    } catch (_) {}
  }
}
