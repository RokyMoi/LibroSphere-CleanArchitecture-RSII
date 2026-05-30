import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../data/models/library_entry.dart';
import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';
import '../widgets/review_dialog.dart';
import 'reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  static const int _pageSize = 4;

  Listenable? _libraryState;
  late Future<_LibraryPage> _future = _load(_page);
  int _page = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextState = SessionScope.read(context).libraryState;
    if (_libraryState == nextState) {
      return;
    }

    _libraryState?.removeListener(_handleLibraryStateChanged);
    _libraryState = nextState;
    _libraryState?.addListener(_handleLibraryStateChanged);
  }

  void _handleLibraryStateChanged() {
    if (!mounted) {
      return;
    }

    unawaited(refresh(forceRefresh: true));
  }

  Future<_LibraryPage> _load(int page) async {
    final session = SessionScope.read(context);
    if (!session.isAuthenticated) {
      return const _LibraryPage(
        items: <_LibraryDisplayItem>[],
        totalPages: 1,
        totalCount: 0,
      );
    }

    final result = await session.getLibraryPage(page: page, pageSize: _pageSize);
    final items = result.items.map((entry) {
      final book = entry.toBookModel();
      return _LibraryDisplayItem(
        entry: entry,
        book: book,
        authorName: session.authorNameForBook(book),
      );
    }).toList();

    return _LibraryPage(
      items: items,
      totalPages: result.totalPages,
      totalCount: result.totalCount,
    );
  }

  void _goToPage(int page) {
    final nextFuture = _load(page);
    setState(() {
      _page = page;
      _future = nextFuture;
    });
  }

  Future<void> refresh({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    final session = SessionScope.read(context);
    if (!session.isAuthenticated) {
      setState(() {
        _page = 1;
        _future = Future.value(
          const _LibraryPage(
            items: <_LibraryDisplayItem>[],
            totalPages: 1,
            totalCount: 0,
          ),
        );
      });
      return;
    }

    if (!forceRefresh && !session.shouldRefreshLibrary()) {
      return;
    }

    final nextFuture = _load(_page);
    setState(() {
      _future = nextFuture;
    });
    await nextFuture;
  }

  @override
  void dispose() {
    _libraryState?.removeListener(_handleLibraryStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.read(context);

    if (!session.isAuthenticated) {
      return const InfoStateView(
        title: 'My Library',
        message: 'Please login to view your library.',
        icon: Icons.menu_book_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final nextFuture = _load(1);
        setState(() {
          _page = 1;
          _future = nextFuture;
        });
        await nextFuture;
      },
      child: FutureBuilder<_LibraryPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return InfoStateView(
              title: 'My Library',
              message: formatErrorMessage(snapshot.error!),
              icon: Icons.menu_book_outlined,
            );
          }

          if (!snapshot.hasData) {
            return const BookListSkeleton();
          }

          final pageData = snapshot.data!;
          final items = pageData.items;

          if (items.isEmpty && pageData.totalCount == 0) {
            return const InfoStateView(
              title: 'My Library',
              message: 'You do not have any purchased books yet.',
              icon: Icons.menu_book_outlined,
            );
          }

          final totalPages = pageData.totalPages;
          final currentPage = _page.clamp(1, totalPages);
          final showPager = totalPages > 1;

          // The current page fell out of range (e.g. books were refunded while
          // we sat on the last page). Snap back to a valid page on the next frame.
          if (items.isEmpty && pageData.totalCount > 0 && _page != currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _page != currentPage) {
                _goToPage(currentPage);
              }
            });
            return const BookListSkeleton();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: items.length + 2 + (showPager ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SectionHeader(
                  title: 'My Library',
                  count: pageData.totalCount,
                );
              }
              if (index == 1) {
                return const SizedBox(height: 26);
              }
              if (showPager && index == items.length + 2) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: PaginationControls(
                    page: currentPage,
                    totalPages: totalPages,
                    onPrevious: currentPage > 1
                        ? () => _goToPage(currentPage - 1)
                        : null,
                    onNext: currentPage < totalPages
                        ? () => _goToPage(currentPage + 1)
                        : null,
                  ),
                );
              }

              final item = items[index - 2];
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(
                      imageUrl: item.book.imageLink ?? item.entry.imageLink,
                      width: 90,
                      height: 135,
                      radius: 0,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.book.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.authorName,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 174,
                              ),
                              child: PrimaryPillButton(
                                label: 'Open Reader',
                                compact: true,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(
                                      book: item.book,
                                      session: session,
                                      onNavigateToTab: widget.onNavigateToTab,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => _openReview(item.book),
                            child: const Text(
                              'Write a Review?',
                              style: TextStyle(
                                color: brandBlueDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openReview(BookModel book) async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => ReviewDialog(book: book),
    );
    if (!mounted || submitted != true) {
      return;
    }

    showSuccessSnackBar(context, 'Your review was published successfully.');
  }
}

class _LibraryPage {
  const _LibraryPage({
    required this.items,
    required this.totalPages,
    required this.totalCount,
  });

  final List<_LibraryDisplayItem> items;
  final int totalPages;
  final int totalCount;
}

class _LibraryDisplayItem {
  _LibraryDisplayItem({
    required this.entry,
    required this.book,
    required this.authorName,
  });

  final LibraryEntry entry;
  final BookModel book;
  final String authorName;
}
