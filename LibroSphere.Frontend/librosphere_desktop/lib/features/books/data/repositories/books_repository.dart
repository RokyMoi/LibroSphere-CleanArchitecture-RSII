import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../genres/data/models/admin_genre_model.dart';
import '../models/admin_author_model.dart';
import '../models/admin_book_model.dart';
import '../models/book_assets_model.dart';
import '../models/book_lookup_data.dart';
import '../models/books_page_bootstrap_model.dart';
import '../models/books_data_model.dart';
import '../models/picked_file_payload.dart';
import '../services/books_api_service.dart';

class BooksRepository {
  BooksRepository(this._apiService);

  final BooksApiService _apiService;
  BookLookupData? _cachedLookupData;

  Future<Result<BooksDataModel>> loadBooksPage(
    String token, {
    required int page,
    int pageSize = 12,
    String? searchTerm,
  }) async {
    try {
      final booksPage = await _apiService.getBooks(
        token,
        page: page,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );
      return Success<BooksDataModel>(
        BooksDataModel(
          books: booksPage.books,
          page: booksPage.page,
          totalPages: booksPage.totalPages,
          totalCount: booksPage.totalCount,
          hasPreviousPage: booksPage.hasPreviousPage,
          hasNextPage: booksPage.hasNextPage,
        ),
      );
    } on AppException catch (exception) {
      return ErrorResult<BooksDataModel>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<BooksDataModel>(
        Failure(message: exception.toString()),
      );
    }
  }

  Future<Result<BooksPageBootstrapModel>> loadBooksPageBootstrap(
    String token, {
    required int page,
    int pageSize = 12,
  }) async {
    try {
      final bootstrap = await _apiService.getBooksPageBootstrap(
        token,
        page: page,
        pageSize: pageSize,
      );
      _cachedLookupData = BookLookupData(
        authors: bootstrap.authors,
        genres: bootstrap.genres,
      );
      return Success<BooksPageBootstrapModel>(bootstrap);
    } on AppException catch (exception) {
      return ErrorResult<BooksPageBootstrapModel>(
        Failure.fromException(exception),
      );
    } catch (exception) {
      return ErrorResult<BooksPageBootstrapModel>(
        Failure(message: exception.toString()),
      );
    }
  }

  Future<Result<BookLookupData>> loadLookupData(
    String token, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedLookupData != null) {
      return Success<BookLookupData>(_cachedLookupData!);
    }

    try {
      final futures = await Future.wait<Object>([
        _apiService.getAuthors(token),
        _apiService.getGenres(token),
      ]);

      final lookupData = BookLookupData(
        authors: futures[0] as List<AdminAuthorModel>,
        genres: futures[1] as List<AdminGenreModel>,
      );

      _cachedLookupData = lookupData;
      return Success<BookLookupData>(lookupData);
    } on AppException catch (exception) {
      return ErrorResult<BookLookupData>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<BookLookupData>(
        Failure(message: exception.toString()),
      );
    }
  }

  void clearLookupCache() {
    _cachedLookupData = null;
  }

  Future<Result<BookAssetsModel>> getBookAssets(
    String token,
    String bookId,
  ) async {
    try {
      final assets = await _apiService.getBookAssets(token, bookId);
      return Success<BookAssetsModel>(assets);
    } on AppException catch (exception) {
      return ErrorResult<BookAssetsModel>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<BookAssetsModel>(
        Failure(message: exception.toString()),
      );
    }
  }

  Future<Result<void>> saveBook({
    required String token,
    required String authorId,
    required List<String> genreIds,
    required String title,
    required String description,
    required String priceText,
    required AdminBookModel? existingBook,
    required String imageLink,
    required String pdfLink,
    PickedFilePayload? imageFile,
    PickedFilePayload? pdfFile,
    UploadProgressCallback? onUploadProgress,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final normalizedPrice = double.tryParse(priceText.replaceAll(',', '.'));

    if (normalizedTitle.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'Book title is required.'),
      );
    }

    if (authorId.trim().isEmpty) {
      return const ErrorResult<void>(Failure(message: 'Author is required.'));
    }

    if (genreIds.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'At least one genre is required.'),
      );
    }

    if (normalizedDescription.isEmpty) {
      return const ErrorResult<void>(
        Failure(message: 'Description is required.'),
      );
    }

    if (normalizedPrice == null || normalizedPrice <= 0) {
      return const ErrorResult<void>(Failure(message: 'Enter a valid price.'));
    }

    if (existingBook == null && (imageFile == null || pdfFile == null)) {
      return const ErrorResult<void>(
        Failure(message: 'Image and PDF are required for a new book.'),
      );
    }

    try {
      if (existingBook == null) {
        await _apiService.createBook(
          token: token,
          title: normalizedTitle,
          description: normalizedDescription,
          priceAmount: normalizedPrice,
          currencyCode: 'USD',
          authorId: authorId,
          genreIds: genreIds,
          imageFile: imageFile!,
          pdfFile: pdfFile!,
          onProgress: onUploadProgress,
        );
      } else {
        await _apiService.updateBook(
          token: token,
          bookId: existingBook.id,
          title: normalizedTitle,
          description: normalizedDescription,
          priceAmount: normalizedPrice,
          currencyCode: 'USD',
          authorId: authorId,
          genreIds: genreIds,
          imageLink: imageLink,
          pdfLink: pdfLink,
          imageFile: imageFile,
          pdfFile: pdfFile,
          onProgress: onUploadProgress,
        );
      }

      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }

  Future<Result<void>> deleteBook({
    required String token,
    required AdminBookModel book,
  }) async {
    try {
      await _apiService.deleteBook(token: token, bookId: book.id);
      return const Success<void>(null);
    } on AppException catch (exception) {
      return ErrorResult<void>(Failure.fromException(exception));
    } catch (exception) {
      return ErrorResult<void>(Failure(message: exception.toString()));
    }
  }
}
