import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/viewmodels/notification_viewmodel.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_widgets.dart';
import 'notifications_screen.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.book,
    required this.session,
    required this.onNavigateToTab,
  });

  final BookModel book;
  final SessionViewModel session;
  final ValueChanged<int> onNavigateToTab;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const _maxCachedBooks = 12;
  static const _maxCacheBytes = 250 * 1024 * 1024;
  static const _progressUpdateThrottle = Duration(milliseconds: 120);

  late Future<_PreparedReaderDocument> _prepareFuture = _prepareDocument();
  double? _downloadProgress;
  String _loadingMessage = 'Preparing your book...';
  DateTime? _lastProgressUiUpdate;

  Future<String> _resolvePdfUrl() async {
    try {
      return await widget.session.getReadUrl(widget.book.id);
    } catch (error) {
      final fallbackUrl = widget.book.pdfLink;
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return fallbackUrl;
      }

      throw Exception(formatErrorMessage(error));
    }
  }

  Future<_PreparedReaderDocument> _prepareDocument({
    bool forceDownload = false,
  }) async {
    final cachePath = await _resolveCachePath(widget.book.id);
    final pdfFile = File(cachePath.pdfPath);

    if (!forceDownload && await pdfFile.exists()) {
      final fileLength = await pdfFile.length();
      if (fileLength > 0) {
        return _PreparedReaderDocument(pdfPath: cachePath.pdfPath);
      }
    }

    _updateLoadingState('Preparing your book...', null);
    final pdfUrl = await _resolvePdfUrl();
    _updateLoadingState('Downloading book to your device...', 0);
    final downloadedFile = await _downloadPdf(pdfUrl, pdfFile);

    return _PreparedReaderDocument(pdfPath: downloadedFile.path);
  }

  Future<_ReaderCachePath> _resolveCachePath(String bookId) async {
    final baseDirectory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}reader_cache',
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    unawaited(_pruneCacheDirectory(cacheDirectory));

    return _ReaderCachePath(
      pdfPath: '${cacheDirectory.path}${Platform.pathSeparator}$bookId.pdf',
    );
  }

  Future<void> _pruneCacheDirectory(Directory cacheDirectory) async {
    try {
      final pdfFiles = await cacheDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.pdf'))
          .cast<File>()
          .toList();

      final entries = <({File file, DateTime modified, int length})>[];
      for (final file in pdfFiles) {
        final stat = await file.stat();
        entries.add((
          file: file,
          modified: stat.modified,
          length: stat.size,
        ));
      }

      if (entries.length <= _maxCachedBooks) {
        var totalBytes = 0;
        for (final item in entries) {
          totalBytes += item.length;
        }
        if (totalBytes <= _maxCacheBytes) {
          return;
        }
      }

      entries.sort((a, b) => a.modified.compareTo(b.modified));
      var totalBytes = entries.fold<int>(0, (sum, item) => sum + item.length);

      while (entries.length > _maxCachedBooks || totalBytes > _maxCacheBytes) {
        final oldest = entries.removeAt(0);
        totalBytes -= oldest.length;
        if (await oldest.file.exists()) {
          await oldest.file.delete();
        }
      }
    } catch (_) {
      // Cache cleanup should never block reader startup.
    }
  }

  Future<File> _downloadPdf(String pdfUrl, File destinationFile) async {
    final tempFile = File('${destinationFile.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', Uri.parse(pdfUrl));
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Unable to download this book right now.');
      }

      sink = tempFile.openWrite();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          _updateProgressThrottled(receivedBytes, totalBytes);
        }
      }
    } finally {
      await sink?.flush();
      await sink?.close();
      client.close();
    }

    if (!await tempFile.exists() || await tempFile.length() == 0) {
      throw Exception('Downloaded file is empty.');
    }

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    return tempFile.rename(destinationFile.path);
  }

  void _updateLoadingState(String message, double? progress) {
    if (!mounted) {
      _loadingMessage = message;
      _downloadProgress = progress;
      return;
    }

    setState(() {
      _loadingMessage = message;
      _downloadProgress = progress;
    });
  }

  void _updateProgressThrottled(int receivedBytes, int totalBytes) {
    final now = DateTime.now();
    if (_lastProgressUiUpdate != null &&
        now.difference(_lastProgressUiUpdate!) < _progressUpdateThrottle) {
      return;
    }

    _lastProgressUiUpdate = now;
    _updateLoadingState(
      'Downloading book to your device...',
      receivedBytes / totalBytes,
    );
  }

  void _retry() {
    setState(() {
      _downloadProgress = null;
      _loadingMessage = 'Preparing your book...';
      _lastProgressUiUpdate = null;
      _prepareFuture = _prepareDocument(forceDownload: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PreparedReaderDocument>(
      future: _prepareFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ReaderScaffold(
            onNavigateToTab: widget.onNavigateToTab,
            child: _ReaderErrorState(
              message: formatErrorMessage(snapshot.error!),
              onRetry: _retry,
            ),
          );
        }

        if (!snapshot.hasData) {
          return _ReaderScaffold(
            onNavigateToTab: widget.onNavigateToTab,
            child: _ReaderLoadingState(
              message: _loadingMessage,
              progress: _downloadProgress,
            ),
          );
        }

        return _ReaderContentScreen(
          book: widget.book,
          session: widget.session,
          onNavigateToTab: widget.onNavigateToTab,
          document: snapshot.data!,
        );
      },
    );
  }
}

class _ReaderScaffold extends StatelessWidget {
  const _ReaderScaffold({
    required this.child,
    required this.onNavigateToTab,
  });

  final Widget child;
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _ReaderHeader(),
            Expanded(child: child),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AppBottomNavigationBar(
                currentIndex: 1,
                onTap: onNavigateToTab,
                embedded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderContentScreen extends StatefulWidget {
  const _ReaderContentScreen({
    required this.book,
    required this.session,
    required this.onNavigateToTab,
    required this.document,
  });

  final BookModel book;
  final SessionViewModel session;
  final ValueChanged<int> onNavigateToTab;
  final _PreparedReaderDocument document;

  @override
  State<_ReaderContentScreen> createState() => _ReaderContentScreenState();
}

class _ReaderContentScreenState extends State<_ReaderContentScreen> {
  static const _defaultZoomLevel = 1.0;
  static const _minZoomLevel = 1.0;
  static const _maxZoomLevel = 3.0;

  final PdfViewerController _pdfViewerController = PdfViewerController();
  final ValueNotifier<int> _notificationPlaceholder = ValueNotifier<int>(0);

  NotificationViewModel? _notifications;
  SharedPreferences? _prefs;

  int _currentPage = 1;
  int _pageCount = 0;
  int _restoredPage = 1;
  bool _didRestorePage = false;
  double _zoomLevel = _defaultZoomLevel;

  String get _bookKey => widget.book.id;
  String get _lastPageKey => 'reader.lastPage.$_bookKey';
  String get _zoomLevelKey => 'reader.zoomLevel';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    unawaited(_restoreReaderState());
  }

  @override
  void dispose() {
    unawaited(_persistCurrentPage());
    _notifications?.stopPolling();
    _notifications?.dispose();
    _notificationPlaceholder.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _initializeNotifications() {
    final token = widget.session.accessToken;
    if (token == null) {
      return;
    }

    final notifications = NotificationViewModel(widget.session.services);
    notifications.startPolling(token);
    _notifications = notifications;
  }

  Future<void> _restoreReaderState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    final savedPage = prefs.getInt(_lastPageKey) ?? 1;
    final savedZoom = prefs.getDouble(_zoomLevelKey) ?? _defaultZoomLevel;

    setState(() {
      _prefs = prefs;
      _restoredPage = savedPage < 1 ? 1 : savedPage;
      _currentPage = _restoredPage;
      _zoomLevel = savedZoom.clamp(_minZoomLevel, _maxZoomLevel);
    });
  }

  Future<void> _persistCurrentPage() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await prefs.setInt(_lastPageKey, _currentPage);
  }

  Future<void> _persistZoomLevel() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await prefs.setDouble(_zoomLevelKey, _zoomLevel);
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    final safePageCount = details.document.pages.count;
    final targetPage = _restoredPage.clamp(1, safePageCount);

    setState(() {
      _pageCount = safePageCount;
      _currentPage = targetPage;
    });

    if (!_didRestorePage) {
      _didRestorePage = true;
      if (targetPage > 1) {
        _pdfViewerController.jumpToPage(targetPage);
      }
      if (_zoomLevel != _defaultZoomLevel) {
        _pdfViewerController.zoomLevel = _zoomLevel;
      }
    }
  }

  void _handlePageChanged(PdfPageChangedDetails details) {
    if (_currentPage == details.newPageNumber) {
      return;
    }

    setState(() => _currentPage = details.newPageNumber);
    unawaited(_persistCurrentPage());
  }

  void _changeZoom(double delta) {
    final nextZoomLevel =
        (_zoomLevel + delta).clamp(_minZoomLevel, _maxZoomLevel).toDouble();
    if (nextZoomLevel == _zoomLevel) {
      return;
    }

    _pdfViewerController.zoomLevel = nextZoomLevel;
    setState(() => _zoomLevel = nextZoomLevel);
    unawaited(_persistZoomLevel());
  }

  void _openNotifications() {
    final notifications = _notifications;
    if (notifications == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(viewModel: notifications),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageLabel = _pageCount == 0
        ? 'PAGE $_currentPage'
        : 'PAGE $_currentPage / $_pageCount';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _ReaderHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SfPdfViewer.file(
                                  File(widget.document.pdfPath),
                                  controller: _pdfViewerController,
                                  canShowPaginationDialog: false,
                                  enableDoubleTapZooming: true,
                                  pageSpacing: 14,
                                  onDocumentLoaded: _handleDocumentLoaded,
                                  onPageChanged: _handlePageChanged,
                                ),
                              ),
                              Positioned(
                                top: 14,
                                left: 20,
                                right: 20,
                                child: IgnorePointer(
                                  child: Center(
                                    child: Text(
                                      widget.book.title.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF7A7A7A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: _ReaderOverlayBar(
                        pageLabel: pageLabel,
                        canZoomOut: _zoomLevel > _minZoomLevel,
                        canZoomIn: _zoomLevel < _maxZoomLevel,
                        onZoomOut: () => _changeZoom(-0.25),
                        onZoomIn: () => _changeZoom(0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: ListenableBuilder(
                listenable: _notifications ?? _notificationPlaceholder,
                builder: (context, _) {
                  return AppBottomNavigationBar(
                    currentIndex: 1,
                    onTap: widget.onNavigateToTab,
                    embedded: true,
                    showNotifications: true,
                    unreadCount: _notifications?.unreadCount ?? 0,
                    onBellTap: _openNotifications,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Row(
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  color: brandBlue,
                  size: 28,
                ),
                SizedBox(width: 4),
                Text(
                  'Reader',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderOverlayBar extends StatelessWidget {
  const _ReaderOverlayBar({
    required this.pageLabel,
    required this.canZoomOut,
    required this.canZoomIn,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final String pageLabel;
  final bool canZoomOut;
  final bool canZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _ReaderOverlayButton(
            icon: Icons.zoom_in_rounded,
            enabled: canZoomIn,
            onTap: onZoomIn,
          ),
          const SizedBox(width: 10),
          _ReaderOverlayButton(
            icon: Icons.zoom_out_rounded,
            enabled: canZoomOut,
            onTap: onZoomOut,
          ),
          const Spacer(),
          Text(
            pageLabel,
            style: const TextStyle(
              color: brandBlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 94),
        ],
      ),
    );
  }
}

class _ReaderOverlayButton extends StatelessWidget {
  const _ReaderOverlayButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 32,
          color: enabled ? brandBlue : const Color(0xFF8FC5FF),
        ),
      ),
    );
  }
}

class _ReaderLoadingState extends StatelessWidget {
  const _ReaderLoadingState({
    required this.message,
    required this.progress,
  });

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null ? null : (progress! * 100).clamp(0, 100);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, size: 52, color: brandBlueDark),
            const SizedBox(height: 14),
            const Text(
              'Opening book',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: brandBlueDark,
                backgroundColor: Colors.white,
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 10),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: brandBlueDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReaderErrorState extends StatelessWidget {
  const _ReaderErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 52, color: brandBlueDark),
            const SizedBox(height: 14),
            const Text(
              'This book could not be opened.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(label: 'Try Again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _PreparedReaderDocument {
  const _PreparedReaderDocument({
    required this.pdfPath,
  });

  final String pdfPath;
}

class _ReaderCachePath {
  const _ReaderCachePath({
    required this.pdfPath,
  });

  final String pdfPath;
}
