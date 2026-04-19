import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final BookModel book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  late Future<String> _pdfFuture = _resolvePdfUrl();
  String? _viewerError;
  int _page = 1;
  int _pageCount = 1;

  Future<String> _resolvePdfUrl() async {
    try {
      return await SessionScope.read(context).getReadUrl(widget.book.id);
    } catch (error) {
      final fallbackUrl = widget.book.pdfLink;
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return fallbackUrl;
      }

      throw Exception(formatErrorMessage(error));
    }
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
      _pdfFuture = _resolvePdfUrl();
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
                child: FutureBuilder<String>(
                  future: _pdfFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ReaderErrorState(
                        message: formatErrorMessage(snapshot.error!),
                        onRetry: _retry,
                      );
                    }

                    if (!snapshot.hasData) {
                      return const CenteredLoadingIndicator();
                    }

                    if (_viewerError != null) {
                      return _ReaderErrorState(
                        message: _viewerError!,
                        onRetry: _retry,
                      );
                    }

                    return SfPdfViewer.network(
                      snapshot.data!,
                      controller: _controller,
                      onPageChanged: (details) => setState(() => _page = details.newPageNumber),
                      onDocumentLoaded: (details) => setState(() => _pageCount = details.document.pages.count),
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
                  MobileBottomNavigation(currentIndex: 1, onTap: (_) {}, embedded: true),
                ],
              ),
            ),
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
