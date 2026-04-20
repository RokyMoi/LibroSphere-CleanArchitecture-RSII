import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_genre_model.dart';
import '../../data/models/genres_page_model.dart';
import '../../data/repositories/genres_repository.dart';

class GenresViewModel extends ChangeNotifier {
  GenresViewModel(
    this._repository,
    this._token, {
    Future<void> Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged;

  final GenresRepository _repository;
  final String _token;
  final Future<void> Function()? _onDataChanged;
  final int pageSize = 10;
  bool _hasLoaded = false;

  bool isLoading = true;
  bool isSaving = false;
  String? deletingGenreId;
  Failure? failure;
  List<AdminGenreModel> genres = <AdminGenreModel>[];
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
    final result = await _repository.getGenres(
      _token,
      page: targetPage,
      pageSize: pageSize,
    );

    switch (result) {
      case Success<GenresPageModel>(value: final loadedPage):
        genres = loadedPage.items;
        currentPage = loadedPage.page;
        totalPages = loadedPage.totalPages;
        totalCount = loadedPage.totalCount;
        hasPreviousPage = loadedPage.hasPreviousPage;
        hasNextPage = loadedPage.hasNextPage;
        _hasLoaded = true;
      case ErrorResult<GenresPageModel>(failure: final error):
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

  Future<Result<void>> saveGenre({
    required AdminGenreModel? existingGenre,
    required String name,
  }) async {
    isSaving = true;
    notifyListeners();

    final result = await _repository.saveGenre(
      token: _token,
      existingGenre: existingGenre,
      name: name,
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

  Future<Result<void>> deleteGenre(AdminGenreModel genre) async {
    deletingGenreId = genre.id;
    notifyListeners();

    final result = await _repository.deleteGenre(
      token: _token,
      genre: genre,
    );

    deletingGenreId = null;

    if (result is Success<void>) {
      final nextPage = genres.length == 1 && currentPage > 1
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
