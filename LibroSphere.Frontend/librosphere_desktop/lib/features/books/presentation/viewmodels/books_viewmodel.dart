import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../genres/data/models/admin_genre_model.dart';
import '../../data/models/admin_author_model.dart';
import '../../data/models/admin_book_model.dart';
import '../../data/models/book_assets_model.dart';
import '../../data/models/book_lookup_data.dart';
import '../../data/models/books_page_bootstrap_model.dart';
import '../../data/models/books_data_model.dart';
import '../../data/models/picked_file_payload.dart';
import '../../data/repositories/books_repository.dart';

class BooksViewModel extends ChangeNotifier {
  BooksViewModel(
    this._repository,
    this._token, {
    Future<void> Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged;

  final BooksRepository _repository;
  final String _token;
  final Future<void> Function()? _onDataChanged;
  final int pageSize = 12;
  bool _hasLoaded = false;
  bool _hasLookupData = false;
  final Map<String, String> _authorNames = <String, String>{};

  bool isLoading = true;
  bool isSaving = false;
  String? deletingBookId;
  Failure? failure;
  List<AdminAuthorModel> authors = <AdminAuthorModel>[];
  List<AdminGenreModel> genres = <AdminGenreModel>[];
  List<AdminBookModel> books = <AdminBookModel>[];
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  bool hasPreviousPage = false;
  bool hasNextPage = false;
  double uploadProgress = 0;
  String savingStatus = '';

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
    if (!_hasLookupData) {
      final bootstrapResult = await _repository.loadBooksPageBootstrap(
        _token,
        page: targetPage,
        pageSize: pageSize,
      );

      switch (bootstrapResult) {
        case Success<BooksPageBootstrapModel>(value: final bootstrap):
          _applyBooksData(bootstrap.booksPage);
          _applyLookupData(
            authorsData: bootstrap.authors,
            genresData: bootstrap.genres,
          );
          _hasLoaded = true;
        case ErrorResult<BooksPageBootstrapModel>(failure: final error):
          await _loadLegacyPage(targetPage);
          if (!_hasLoaded) {
            failure = error is Failure
                ? error
                : Failure(message: error.toString());
          }
      }
    } else {
      final pageResult = await _repository.loadBooksPage(
        _token,
        page: targetPage,
        pageSize: pageSize,
      );

      switch (pageResult) {
        case Success<BooksDataModel>(value: final data):
          _applyBooksData(data);
          _hasLoaded = true;
        case ErrorResult<BooksDataModel>(failure: final error):
          failure = error is Failure
              ? error
              : Failure(message: error.toString());
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLegacyPage(int targetPage) async {
    final pageResultFuture = _repository.loadBooksPage(
      _token,
      page: targetPage,
      pageSize: pageSize,
    );
    final lookupResultFuture = _repository.loadLookupData(_token);

    final pageResult = await pageResultFuture;
    final lookupResult = await lookupResultFuture;

    switch (pageResult) {
      case Success<BooksDataModel>(value: final data):
        _applyBooksData(data);
        _hasLoaded = true;
      case ErrorResult<BooksDataModel>(failure: final error):
        failure = error is Failure ? error : Failure(message: error.toString());
    }

    _applyLookupResult(lookupResult);
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

  Future<Result<BookAssetsModel>> loadAssets(String bookId) {
    return _repository.getBookAssets(_token, bookId);
  }

  Future<void> refreshLookupData() async {
    _repository.clearLookupCache();

    if (!_hasLoaded) {
      _hasLookupData = false;
      return;
    }

    final lookupResult = await _repository.loadLookupData(
      _token,
      forceRefresh: true,
    );
    if (lookupResult is Success<BookLookupData>) {
      _applyLookupResult(lookupResult);
      notifyListeners();
    }
  }

  Future<Result<void>> saveBook({
    required AdminBookModel? existingBook,
    required String title,
    required String description,
    required String authorId,
    required List<String> genreIds,
    required String priceText,
    required String imageLink,
    required String pdfLink,
    PickedFilePayload? imageFile,
    PickedFilePayload? pdfFile,
  }) async {
    isSaving = true;
    uploadProgress = 0;
    savingStatus = 'Uploading files...';
    failure = null;
    notifyListeners();

    final result = await _repository.saveBook(
      token: _token,
      authorId: authorId,
      genreIds: genreIds,
      title: title,
      description: description,
      priceText: priceText,
      existingBook: existingBook,
      imageLink: imageLink,
      pdfLink: pdfLink,
      imageFile: imageFile,
      pdfFile: pdfFile,
      onUploadProgress: _setUploadProgress,
    );

    if (result is Success<void>) {
      uploadProgress = 1;
      savingStatus = 'Refreshing books...';
      notifyListeners();

      await load(page: existingBook == null ? 1 : currentPage);

      final refreshFailure = failure;
      isSaving = false;
      uploadProgress = 0;
      savingStatus = '';
      notifyListeners();

      if (refreshFailure != null) {
        return ErrorResult<void>(refreshFailure);
      }

      await _notifyDataChanged();
      return result;
    }

    isSaving = false;
    uploadProgress = 0;
    savingStatus = '';
    notifyListeners();
    return result;
  }

  void _setUploadProgress(double progress) {
    uploadProgress = progress.clamp(0, 1).toDouble();
    notifyListeners();
  }

  String authorName(String authorId) {
    return _authorNames[authorId] ?? 'Unknown';
  }

  Future<Result<void>> deleteBook(AdminBookModel book) async {
    deletingBookId = book.id;
    failure = null;
    notifyListeners();

    final result = await _repository.deleteBook(token: _token, book: book);

    deletingBookId = null;

    if (result is Success<void>) {
      final nextPage = books.length == 1 && currentPage > 1
          ? currentPage - 1
          : currentPage;
      await load(page: nextPage);
      await _notifyDataChanged();
    } else {
      notifyListeners();
    }

    return result;
  }

  void _applyLookupResult(Result<BookLookupData> result) {
    switch (result) {
      case Success<BookLookupData>(value: final data):
        _applyLookupData(authorsData: data.authors, genresData: data.genres);
      case ErrorResult<BookLookupData>(failure: final error):
        failure = error is Failure ? error : Failure(message: error.toString());
    }
  }

  void _applyBooksData(BooksDataModel data) {
    books = data.books;
    currentPage = data.page;
    totalPages = data.totalPages;
    totalCount = data.totalCount;
    hasPreviousPage = data.hasPreviousPage;
    hasNextPage = data.hasNextPage;
  }

  void _applyLookupData({
    required List<AdminAuthorModel> authorsData,
    required List<AdminGenreModel> genresData,
  }) {
    authors = authorsData;
    genres = genresData;
    _authorNames
      ..clear()
      ..addEntries(
        authorsData.map((author) => MapEntry(author.id, author.name)),
      );
    _hasLookupData = true;
  }

  Future<void> _notifyDataChanged() async {
    try {
      await _onDataChanged?.call();
    } catch (_) {}
  }
}
