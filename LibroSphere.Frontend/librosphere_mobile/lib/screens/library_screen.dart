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
  Listenable? _libraryState;
  late Future<List<_LibraryDisplayItem>> _future = _load();

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

  Future<List<_LibraryDisplayItem>> _load({bool forceRefresh = false}) async {
    final session = SessionScope.read(context);
    if (!session.isAuthenticated) {
      return <_LibraryDisplayItem>[];
    }

    final entries = await session.getLibraryEntries(forceRefresh: forceRefresh);
    return entries.map((entry) {
      final book = entry.toBookModel();
      return _LibraryDisplayItem(
        entry: entry,
        book: book,
        authorName: session.authorNameForBook(book),
      );
    }).toList();
  }

  Future<void> refresh({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    final session = SessionScope.read(context);
    if (!session.isAuthenticated) {
      setState(() {
        _future = Future.value(<_LibraryDisplayItem>[]);
      });
      return;
    }

    if (!forceRefresh && !session.shouldRefreshLibrary()) {
      return;
    }

    final nextFuture = _load(forceRefresh: forceRefresh);
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
        final nextFuture = _load(forceRefresh: true);
        setState(() {
          _future = nextFuture;
        });
        await nextFuture;
      },
      child: FutureBuilder<List<_LibraryDisplayItem>>(
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

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const InfoStateView(
              title: 'My Library',
              message: 'You do not have any purchased books yet.',
              icon: Icons.menu_book_outlined,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: items.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SectionHeader(title: 'My Library', count: items.length);
              }
              if (index == 1) {
                return const SizedBox(height: 26);
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
