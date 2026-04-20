import 'package:flutter/material.dart';

import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/common_widgets.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  SessionViewModel? _session;
  late Future<List<BookModel>> _future = _load();

  Future<List<BookModel>> _load() async {
    final session = SessionScope.read(context);
    if (!session.isAuthenticated) {
      return <BookModel>[];
    }

    return session.getWishlistBooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextSession = SessionScope.read(context);
    if (_session == nextSession) {
      return;
    }

    _session?.removeListener(_handleSessionChanged);
    _session = nextSession;
    _session!.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    _session?.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = _load();
    });
  }

  Future<void> _moveToCart(BookModel book) async {
    try {
      await context.session.moveWishlistBookToCart(book);
      if (!mounted) return;
      showSuccessSnackBar(context, 'The book was moved from your wishlist to the shopping cart.');
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    }
  }

  Future<void> _removeFromWishlist(String bookId) async {
    try {
      await context.session.removeFromWishlist(bookId);
      if (!mounted) return;
      showDestructiveSnackBar(context, 'The book was removed from your wishlist.');
      setState(() {
        _future = _load();
      });
    } catch (error) {
      if (!mounted) return;
      showDestructiveSnackBar(context, formatErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.session;

    if (!session.isAuthenticated) {
      return const InfoStateView(
        title: 'Wishlist',
        message: 'Please login to view your wishlist.',
        icon: Icons.bookmark_border_rounded,
      );
    }

    return FutureBuilder<List<BookModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InfoStateView(
            title: 'Wishlist',
            message: formatErrorMessage(snapshot.error!),
            icon: Icons.bookmark_border_rounded,
          );
        }

        if (!snapshot.hasData) {
          return const CenteredLoadingIndicator();
        }

        final books = snapshot.data!;

        if (books.isEmpty) {
          return const InfoStateView(
            title: 'Wishlist',
            message: 'Your wishlist is empty.',
            icon: Icons.bookmark_border_rounded,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            SectionHeader(title: 'Wishlist', count: books.length),
            const SizedBox(height: 26),
            ...books.map((book) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(imageUrl: book.imageLink, width: 88, height: 130, radius: 0),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(session.authorNameForBook(book), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryPillButton(
                                label: 'Move to Cart',
                                compact: true,
                                onPressed: () => _moveToCart(book),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 96,
                              child: PrimaryPillButton(
                                label: 'Delete',
                                compact: true,
                                onPressed: () => _removeFromWishlist(book.id),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('\$${book.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
}
