import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/pdf/pdf_report_service.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../../../books/data/models/admin_book_model.dart';
import '../../../books/data/repositories/books_repository.dart';
import '../../../dashboard/data/models/dashboard_stats_model.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../../genres/data/models/admin_genre_model.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    required DashboardRepository dashboardRepository,
    required BooksRepository booksRepository,
    required String token,
  })  : _dashboardRepository = dashboardRepository,
        _booksRepository = booksRepository,
        _token = token;

  final DashboardRepository _dashboardRepository;
  final BooksRepository _booksRepository;
  final PdfReportService _pdfService = PdfReportService();
  final String _token;

  bool _hasLoaded = false;

  bool isLoading = true;
  bool isGeneratingPlatform = false;
  bool isGeneratingCatalogue = false;

  String? platformError;
  String? catalogueError;

  DashboardStatsModel? _stats;
  List<AdminBookModel> _books = const [];
  List<AdminAuthorModel> _authors = const [];
  List<AdminGenreModel> _genres = const [];

  Future<void> ensureLoaded() {
    if (_hasLoaded) return Future.value();
    return _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    try {
      final dashResult = await _dashboardRepository.getDashboard(_token);
      if (dashResult case Success<DashboardStatsModel>(value: final stats)) {
        _stats = stats;
      }

      // Force refresh to avoid stale cached lookup data
      final lookupResult =
          await _booksRepository.loadLookupData(_token, forceRefresh: true);
      if (lookupResult case Success(value: final lookup)) {
        _authors = lookup.authors;
        _genres = lookup.genres;
      }

      // Load up to 200 books for catalogue
      final booksResult = await _booksRepository.loadBooksPage(
        _token,
        page: 1,
        pageSize: 200,
      );
      if (booksResult case Success(value: final booksPage)) {
        _books = booksPage.books;
      }

      _hasLoaded = true;
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<Uint8List?> generatePlatformReport() async {
    isGeneratingPlatform = true;
    platformError = null;
    notifyListeners();

    try {
      // Always refresh data before generating to ensure PDF has latest info
      final dashResult = await _dashboardRepository.getDashboard(_token);
      if (dashResult case Success<DashboardStatsModel>(value: final stats)) {
        _stats = stats;
      }

      final stats = _stats;
      if (stats == null) {
        platformError =
            'Could not load dashboard data. Check your connection and try again.';
        return null;
      }

      final bytes = await _pdfService.generatePlatformReport(stats);
      return bytes;
    } catch (e) {
      platformError = 'Failed to generate report: $e';
      return null;
    } finally {
      isGeneratingPlatform = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> generateCatalogueReport() async {
    isGeneratingCatalogue = true;
    catalogueError = null;
    notifyListeners();

    try {
      // Always refresh catalogue data to ensure PDF contains latest books
      final lookupResult =
          await _booksRepository.loadLookupData(_token, forceRefresh: true);
      if (lookupResult case Success(value: final lookup)) {
        _authors = lookup.authors;
        _genres = lookup.genres;
      }

      final booksResult = await _booksRepository.loadBooksPage(
        _token,
        page: 1,
        pageSize: 200,
      );
      if (booksResult case Success(value: final booksPage)) {
        _books = booksPage.books;
      }

      if (_books.isEmpty) {
        catalogueError =
            'No books available to generate catalogue. Check your connection.';
        return null;
      }

      final bytes = await _pdfService.generateBookCatalogueReport(
        books: _books,
        authors: _authors,
        genres: _genres,
      );
      return bytes;
    } catch (e) {
      catalogueError = 'Failed to generate report: $e';
      return null;
    } finally {
      isGeneratingCatalogue = false;
      notifyListeners();
    }
  }
}
