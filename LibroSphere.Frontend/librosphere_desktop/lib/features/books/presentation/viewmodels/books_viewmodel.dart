import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_author_model.dart';
import '../../data/models/admin_book_model.dart';
import '../../data/models/admin_genre_model.dart';
import '../../data/models/book_assets_model.dart';
import '../../data/models/books_data_model.dart';
import '../../data/models/picked_file_payload.dart';
import '../../data/repositories/books_repository.dart';

class BooksViewModel extends ChangeNotifier {
  BooksViewModel(this._repository, this._token);

  final BooksRepository _repository;
  final String _token;
  final int pageSize = 12;

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

  Future<void> load({int? page}) async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final targetPage = page ?? currentPage;
    final result = await _repository.loadBooksPage(
      _token,
      page: targetPage,
      pageSize: pageSize,
    );

    switch (result) {
      case Success<BooksDataModel>(value: final data):
        authors = data.authors;
        genres = data.genres;
        books = data.books;
        currentPage = data.page;
        totalPages = data.totalPages;
        totalCount = data.totalCount;
        hasPreviousPage = data.hasPreviousPage;
        hasNextPage = data.hasNextPage;
      case ErrorResult<BooksDataModel>(failure: final error):
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

  Future<Result<BookAssetsModel>> loadAssets(String bookId) {
    return _repository.getBookAssets(_token, bookId);
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
    for (final author in authors) {
      if (author.id == authorId) {
        return author.name;
      }
    }

    return 'Unknown';
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
    } else {
      notifyListeners();
    }

    return result;
  }
}
