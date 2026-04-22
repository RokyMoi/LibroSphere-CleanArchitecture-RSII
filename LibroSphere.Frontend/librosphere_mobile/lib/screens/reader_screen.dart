import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
    final cachePaths = await _resolveCachePaths(widget.book.id);

    if (!forceDownload) {
      final cachedDocument = await _readCachedDocument(cachePaths);
      if (cachedDocument != null) {
        return cachedDocument;
      }
    }

    final pdfFile = File(cachePaths.pdfPath);
    if (!forceDownload && await pdfFile.exists()) {
      final fileLength = await pdfFile.length();
      if (fileLength > 0) {
        return _parseAndPersistReader(cachePaths, pdfFile);
      }
    }

    _updateLoadingState('Preparing your book...', null);
    final pdfUrl = await _resolvePdfUrl();
    _updateLoadingState('Downloading book to your device...', 0);
    final downloadedFile = await _downloadPdf(pdfUrl, pdfFile);
    return _parseAndPersistReader(cachePaths, downloadedFile);
  }

  Future<_PreparedReaderDocument?> _readCachedDocument(
    _ReaderCachePaths cachePaths,
  ) async {
    final pdfFile = File(cachePaths.pdfPath);
    final parsedFile = File(cachePaths.parsedPath);
    if (!await pdfFile.exists() || !await parsedFile.exists()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await parsedFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final pagesJson = decoded['pages'];
      if (pagesJson is! List) {
        return null;
      }

      final pages = pagesJson
          .map((page) => (page as String).trim())
          .where((page) => page.isNotEmpty)
          .toList();
      if (pages.isEmpty) {
        return null;
      }

      return _PreparedReaderDocument(
        pdfPath: cachePaths.pdfPath,
        parsedPath: cachePaths.parsedPath,
        pages: pages,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_PreparedReaderDocument> _parseAndPersistReader(
    _ReaderCachePaths cachePaths,
    File pdfFile,
  ) async {
    _updateLoadingState('Preparing pages for reading...', null);

    final pdfBytes = await pdfFile.readAsBytes();
    final pages = await compute(_extractPdfPages, pdfBytes);
    if (pages.isEmpty) {
      throw Exception(
        'This PDF could not be converted into reader-friendly text.',
      );
    }

    final parsedFile = File(cachePaths.parsedPath);
    await parsedFile.writeAsString(
      jsonEncode(<String, dynamic>{
        'version': 1,
        'pageCount': pages.length,
        'pages': pages,
      }),
      flush: true,
    );

    return _PreparedReaderDocument(
      pdfPath: cachePaths.pdfPath,
      parsedPath: cachePaths.parsedPath,
      pages: pages,
    );
  }

  Future<_ReaderCachePaths> _resolveCachePaths(String bookId) async {
    final baseDirectory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}reader_cache',
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    unawaited(_pruneCacheDirectory(cacheDirectory));

    return _ReaderCachePaths(
      pdfPath: '${cacheDirectory.path}${Platform.pathSeparator}$bookId.pdf',
      parsedPath: '${cacheDirectory.path}${Platform.pathSeparator}$bookId.json',
    );
  }

  Future<void> _pruneCacheDirectory(Directory cacheDirectory) async {
    try {
      final pdfFiles = await cacheDirectory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.pdf'))
          .cast<File>()
          .toList();

      final pairedEntries = <({File pdf, File parsed, DateTime modified, int length})>[];
      for (final pdf in pdfFiles) {
        final parsed = File(
          pdf.path.replaceFirst(RegExp(r'\.pdf$'), '.json'),
        );
        final stat = await pdf.stat();
        pairedEntries.add((
          pdf: pdf,
          parsed: parsed,
          modified: stat.modified,
          length: stat.size,
        ));
      }

      if (pairedEntries.length <= _maxCachedBooks) {
        var totalBytes = 0;
        for (final item in pairedEntries) {
          totalBytes += item.length;
        }
        if (totalBytes <= _maxCacheBytes) {
          return;
        }
      }

      pairedEntries.sort((a, b) => a.modified.compareTo(b.modified));
      var totalBytes = pairedEntries.fold<int>(
        0,
        (sum, item) => sum + item.length,
      );

      while (
          pairedEntries.length > _maxCachedBooks || totalBytes > _maxCacheBytes) {
        final oldest = pairedEntries.removeAt(0);
        totalBytes -= oldest.length;
        if (await oldest.pdf.exists()) {
          await oldest.pdf.delete();
        }
        if (await oldest.parsed.exists()) {
          await oldest.parsed.delete();
        }
      }
    } catch (_) {
      // Cache cleanup should not block reader startup.
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
            Padding(
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
            ),
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
  static const _defaultFontSize = 18.0;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ValueNotifier<int> _notificationPlaceholder = ValueNotifier<int>(0);

  NotificationViewModel? _notifications;
  SharedPreferences? _prefs;
  Timer? _saveTimer;

  double _fontSize = _defaultFontSize;
  _ReaderThemeMode _themeMode = _ReaderThemeMode.light;
  Set<int> _bookmarks = <int>{};
  int _currentPage = 0;
  bool _didRestorePage = false;

  String get _bookKey => widget.book.id;
  String get _lastPageKey => 'reader.lastPage.$_bookKey';
  String get _bookmarkKey => 'reader.bookmarks.$_bookKey';
  String get _fontSizeKey => 'reader.fontSize';
  String get _themeModeKey => 'reader.themeMode';

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_handleVisibleItemsChanged);
    _initializeNotifications();
    unawaited(_restoreReaderState());
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleVisibleItemsChanged,
    );
    _saveTimer?.cancel();
    unawaited(_persistCurrentPage());
    _notifications?.stopPolling();
    _notifications?.dispose();
    _notificationPlaceholder.dispose();
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

    final savedBookmarks = _decodeBookmarks(prefs.getString(_bookmarkKey));
    final savedFontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    final savedThemeMode = _ReaderThemeModeX.fromStorageValue(
      prefs.getString(_themeModeKey),
    );
    final savedPage = prefs.getInt(_lastPageKey) ?? 0;

    setState(() {
      _prefs = prefs;
      _fontSize = savedFontSize.clamp(14.0, 30.0);
      _themeMode = savedThemeMode;
      _bookmarks = savedBookmarks;
      _currentPage = savedPage.clamp(0, widget.document.pages.length - 1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRestorePage || !_itemScrollController.isAttached) {
        return;
      }

      _didRestorePage = true;
      _itemScrollController.jumpTo(index: _currentPage);
    });
  }

  void _handleVisibleItemsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      return;
    }

    final visibleItems = positions
        .where((position) => position.itemTrailingEdge > 0)
        .toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (visibleItems.isEmpty) {
      return;
    }

    final nextPage = visibleItems.first.index.clamp(
      0,
      widget.document.pages.length - 1,
    );
    if (_currentPage != nextPage && mounted) {
      setState(() => _currentPage = nextPage);
    }

    _schedulePositionPersist();
  }

  void _schedulePositionPersist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_persistCurrentPage()),
    );
  }

  Future<void> _persistCurrentPage() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await prefs.setInt(_lastPageKey, _currentPage);
  }

  Future<void> _persistReaderSettings() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    await Future.wait([
      prefs.setDouble(_fontSizeKey, _fontSize),
      prefs.setString(_themeModeKey, _themeMode.storageValue),
      prefs.setString(_bookmarkKey, jsonEncode(_bookmarks.toList()..sort())),
    ]);
  }

  Set<int> _decodeBookmarks(String? rawBookmarks) {
    if (rawBookmarks == null || rawBookmarks.isEmpty) {
      return <int>{};
    }

    try {
      final decoded = jsonDecode(rawBookmarks);
      if (decoded is! List) {
        return <int>{};
      }

      return decoded
          .whereType<num>()
          .map((page) => page.toInt())
          .where((page) => page >= 0 && page < widget.document.pages.length)
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  void _toggleBookmark() {
    final nextBookmarks = Set<int>.from(_bookmarks);
    if (!nextBookmarks.add(_currentPage)) {
      nextBookmarks.remove(_currentPage);
    }

    setState(() => _bookmarks = nextBookmarks);
    unawaited(_persistReaderSettings());
  }

  void _jumpToPage(int pageIndex) {
    if (!_itemScrollController.isAttached) {
      return;
    }

    _itemScrollController.scrollTo(
      index: pageIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openSearchDialog() async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search in book'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Enter a word or phrase',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    final normalizedQuery = query?.trim().toLowerCase();
    if (!mounted || normalizedQuery == null || normalizedQuery.isEmpty) {
      return;
    }

    final matchIndex = widget.document.pages.indexWhere(
      (page) => page.toLowerCase().contains(normalizedQuery),
    );

    if (matchIndex < 0) {
      showDestructiveSnackBar(
        context,
        'No match found for "$normalizedQuery".',
      );
      return;
    }

    _jumpToPage(matchIndex);
    showSuccessSnackBar(
      context,
      'Jumped to page ${matchIndex + 1}.',
    );
  }

  Future<void> _openReaderOptions() async {
    final palette = _paletteFor(_themeMode);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reader Options',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Font Size',
                      style: TextStyle(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: _fontSize,
                      min: 14,
                      max: 30,
                      divisions: 8,
                      label: _fontSize.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        setSheetState(() {});
                      },
                      onChangeEnd: (_) => unawaited(_persistReaderSettings()),
                    ),
                    Text(
                      'Theme',
                      style: TextStyle(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: _ReaderThemeMode.values.map((mode) {
                        final selected = mode == _themeMode;
                        return ChoiceChip(
                          label: Text(mode.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _themeMode = mode);
                            setSheetState(() {});
                            unawaited(_persistReaderSettings());
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _toggleBookmark();
                          setSheetState(() {});
                        },
                        icon: Icon(
                          _bookmarks.contains(_currentPage)
                              ? Icons.bookmark_remove_rounded
                              : Icons.bookmark_add_rounded,
                        ),
                        label: Text(
                          _bookmarks.contains(_currentPage)
                              ? 'Remove bookmark for current page'
                              : 'Bookmark current page',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final palette = _paletteFor(_themeMode);
    final titleStyle = TextStyle(
      color: palette.text,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chevron_left_rounded,
                              color: brandBlue,
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            Text('Reader', style: titleStyle),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openSearchDialog,
                        icon: Icon(Icons.search_rounded, color: palette.text),
                        tooltip: 'Search',
                      ),
                      IconButton(
                        onPressed: _toggleBookmark,
                        icon: Icon(
                          _bookmarks.contains(_currentPage)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: palette.text,
                        ),
                        tooltip: 'Bookmark',
                      ),
                      IconButton(
                        onPressed: _openReaderOptions,
                        icon: Icon(
                          _themeMode == _ReaderThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.tune_rounded,
                          color: palette.text,
                        ),
                        tooltip: 'Reader options',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Page ${_currentPage + 1} / ${widget.document.pages.length}',
                      style: TextStyle(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_bookmarks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: (_bookmarks.toList()..sort()).map((page) {
                          final isActive = page == _currentPage;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: isActive
                                  ? brandBlue
                                  : palette.cardBackground,
                              labelStyle: TextStyle(
                                color: isActive ? Colors.white : palette.text,
                                fontWeight: FontWeight.w700,
                              ),
                              label: Text('Page ${page + 1}'),
                              onPressed: () => _jumpToPage(page),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: palette.background,
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: widget.document.pages.length,
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: _ReaderPageCard(
                        pageNumber: index + 1,
                        text: widget.document.pages[index],
                        fontSize: _fontSize,
                        palette: palette,
                        bookmarked: _bookmarks.contains(index),
                      ),
                    );
                  },
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

class _ReaderPageCard extends StatelessWidget {
  const _ReaderPageCard({
    required this.pageNumber,
    required this.text,
    required this.fontSize,
    required this.palette,
    required this.bookmarked,
  });

  final int pageNumber;
  final String text;
  final double fontSize;
  final _ReaderPalette palette;
  final bool bookmarked;

  @override
  Widget build(BuildContext context) {
    final displayText = text.trim().isEmpty
        ? '[This page does not contain extractable text.]'
        : text;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.shadowOpacity),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Page $pageNumber',
                style: TextStyle(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              if (bookmarked)
                const Icon(
                  Icons.bookmark_rounded,
                  color: brandBlueDark,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayText,
            style: TextStyle(
              color: palette.text,
              fontSize: fontSize,
              height: 1.7,
            ),
          ),
        ],
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
    required this.parsedPath,
    required this.pages,
  });

  final String pdfPath;
  final String parsedPath;
  final List<String> pages;
}

class _ReaderCachePaths {
  const _ReaderCachePaths({
    required this.pdfPath,
    required this.parsedPath,
  });

  final String pdfPath;
  final String parsedPath;
}

enum _ReaderThemeMode { light, dark }

extension _ReaderThemeModeX on _ReaderThemeMode {
  String get label => this == _ReaderThemeMode.dark ? 'Dark' : 'Light';

  String get storageValue => switch (this) {
    _ReaderThemeMode.light => 'light',
    _ReaderThemeMode.dark => 'dark',
  };

  static _ReaderThemeMode fromStorageValue(String? value) {
    return value == 'dark' ? _ReaderThemeMode.dark : _ReaderThemeMode.light;
  }
}

class _ReaderPalette {
  const _ReaderPalette({
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.text,
    required this.mutedText,
    required this.shadowOpacity,
  });

  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color text;
  final Color mutedText;
  final double shadowOpacity;
}

_ReaderPalette _paletteFor(_ReaderThemeMode themeMode) {
  return switch (themeMode) {
    _ReaderThemeMode.light => const _ReaderPalette(
      background: Color(0xFFF4F7FB),
      surface: Colors.white,
      cardBackground: Colors.white,
      text: Color(0xFF17212E),
      mutedText: Color(0xFF5E6B7B),
      shadowOpacity: 0.06,
    ),
    _ReaderThemeMode.dark => const _ReaderPalette(
      background: Color(0xFF0F1720),
      surface: Color(0xFF17212E),
      cardBackground: Color(0xFF17212E),
      text: Color(0xFFF3F6FA),
      mutedText: Color(0xFF9FB0C4),
      shadowOpacity: 0.16,
    ),
  };
}

List<String> _extractPdfPages(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(document);
    final pages = <String>[];

    for (var pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
      final text = extractor.extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
        layoutText: true,
      );
      final normalized = text
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      pages.add(normalized);
    }

    return pages;
  } finally {
    document.dispose();
  }
}
