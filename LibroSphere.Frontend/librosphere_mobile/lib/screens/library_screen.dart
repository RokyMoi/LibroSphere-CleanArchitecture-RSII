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
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final Future<List<_LibraryDisplayItem>> _future = _load();

  Future<List<_LibraryDisplayItem>> _load() async {
    final session = SessionScope.read(context);
    final entries = await session.getLibraryEntries();
    final items = <_LibraryDisplayItem>[];
    for (final entry in entries) {
      final book = await session.getBook(entry.bookId);
      items.add(_LibraryDisplayItem(
        entry: entry,
        book: book,
        authorName: session.authorName(book.authorId),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_LibraryDisplayItem>>(
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
          return const CenteredLoadingIndicator();
        }

        final items = snapshot.data!;

        if (items.isEmpty) {
          return const InfoStateView(
            title: 'My Library',
            message: 'You do not have any purchased books yet.',
            icon: Icons.menu_book_outlined,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            SectionHeader(title: 'My Library', count: items.length),
            const SizedBox(height: 26),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(imageUrl: item.book.imageLink ?? item.entry.imageLink, width: 90, height: 135, radius: 0),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.book.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(item.authorName, style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 174),
                                child: PrimaryPillButton(
                                  label: 'Open Reader',
                                  compact: true,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReaderScreen(book: item.book),
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
                                style: TextStyle(color: brandBlueDark, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
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
  _LibraryDisplayItem({required this.entry, required this.book, required this.authorName});

  final LibraryEntry entry;
  final BookModel book;
  final String authorName;
}
