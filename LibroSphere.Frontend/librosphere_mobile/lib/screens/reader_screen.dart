import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/common_widgets.dart';

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
  final PdfViewerController _controller = PdfViewerController();
  late Future<File> _documentFuture = _prepareDocument();
  String? _viewerError;
  int _page = 1;
  int _pageCount = 1;
  double? _downloadProgress;
  String _loadingMessage = 'Preparing your book...';

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

  Future<File> _prepareDocument({bool forceDownload = false}) async {
    final cachedFile = await _resolveCachedFile();
    if (!forceDownload && await cachedFile.exists()) {
      final length = await cachedFile.length();
      if (length > 0) {
        return cachedFile;
      }
    }

    _updateLoadingState('Preparing your book...', null);
    final pdfUrl = await _resolvePdfUrl();
    _updateLoadingState('Downloading book to your device...', 0);
    return _downloadPdf(pdfUrl, cachedFile);
  }

  Future<File> _resolveCachedFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}reader_cache',
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    return File(
      '${cacheDirectory.path}${Platform.pathSeparator}${widget.book.id}.pdf',
    );
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
          _updateLoadingState(
            'Downloading book to your device...',
            receivedBytes / totalBytes,
          );
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _viewerError = null;
      _page = 1;
      _pageCount = 1;
      _downloadProgress = null;
      _loadingMessage = 'Preparing your book...';
      _documentFuture = _prepareDocument(forceDownload: true);
    });
  }

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
                        Icon(Icons.chevron_left_rounded, color: brandBlue, size: 28),
                        SizedBox(width: 4),
                        Text('Reader', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF3F3F3),
                child: FutureBuilder<File>(
                  future: _documentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ReaderErrorState(
                        message: formatErrorMessage(snapshot.error!),
                        onRetry: _retry,
                      );
                    }

                    if (!snapshot.hasData) {
                      return _ReaderLoadingState(
                        message: _loadingMessage,
                        progress: _downloadProgress,
                      );
                    }

                    if (_viewerError != null) {
                      return _ReaderErrorState(
                        message: _viewerError!,
                        onRetry: _retry,
                      );
                    }

                    return SfPdfViewer.file(
                      snapshot.data!,
                      controller: _controller,
                      onPageChanged: (details) => setState(() => _page = details.newPageNumber),
                      onDocumentLoaded: (details) => setState(() {
                        _pageCount = details.document.pages.count;
                        _downloadProgress = null;
                      }),
                      onDocumentLoadFailed: (details) => setState(() => _viewerError = details.description),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _controller.zoomLevel += 0.25,
                        icon: const Icon(Icons.zoom_in_rounded, color: brandBlue, size: 34),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _controller.zoomLevel = (_controller.zoomLevel - 0.25).clamp(1.0, 4.0),
                        icon: const Icon(Icons.zoom_out_rounded, color: brandBlue, size: 34),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'PAGE $_page / $_pageCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: brandBlueDark),
                      ),
                    ],
                  ),
                  MobileBottomNavigation(
                    currentIndex: 1,
                    onTap: widget.onNavigateToTab,
                    embedded: true,
                  ),
                ],
              ),
            ),
          ],
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
              'Downloading book',
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
