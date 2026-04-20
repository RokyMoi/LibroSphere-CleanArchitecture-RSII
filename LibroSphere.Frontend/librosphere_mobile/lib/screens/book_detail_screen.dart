import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../data/models/review_model.dart';
import '../features/session/presentation/viewmodels/session_viewmodel.dart';
import '../widgets/common_widgets.dart';
import '../widgets/review_dialog.dart';
import 'reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.session,
    required this.onNavigateToTab,
  });

  final String bookId;
  final SessionViewModel session;
  final ValueChanged<int> onNavigateToTab;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  static const _reviewPageSize = 3;

  bool _didLoad = false;
  bool _loading = true;
  bool _loadingReviewPage = false;
  String? _errorMessage;
  String? _reviewErrorMessage;

  BookModel? _book;
  String _authorName = 'Unknown Author';
  double _averageRating = 0;
  bool _hasLibraryAccess = false;
  int _reviewPage = 1;
  int _reviewTotalPages = 1;
  int _reviewTotalCount = 0;
  List<ReviewModel> _reviews = const <ReviewModel>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }

    _didLoad = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _reviewErrorMessage = null;
    });

    try {
      final session = widget.session;
      final bookFuture = session.getBook(widget.bookId, forceRefresh: true);
      final libraryAccessFuture = session.hasLibraryAccess(widget.bookId);
      final reviewPageFuture = session.getReviewPage(
        widget.bookId,
        page: 1,
        pageSize: _reviewPageSize,
        forceRefresh: true,
      );

      final book = await bookFuture;
      final hasLibraryAccess = await libraryAccessFuture;
      final reviewPage = await reviewPageFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _book = book;
        _authorName = session.authorNameForBook(book);
        _averageRating = book.averageRating;
        _hasLibraryAccess = hasLibraryAccess;
        _reviews = reviewPage.items;
        _reviewPage = reviewPage.page == 0 ? 1 : reviewPage.page;
        _reviewTotalPages = reviewPage.totalPages;
        _reviewTotalCount = reviewPage.totalCount;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _errorMessage = formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadReviewPage(int page) async {
    if (_loadingReviewPage || page < 1 || page == _reviewPage) {
      return;
    }

    setState(() {
      _loadingReviewPage = true;
      _reviewErrorMessage = null;
    });

    try {
      final reviewPage = await widget.session.getReviewPage(
        widget.bookId,
        page: page,
        pageSize: _reviewPageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reviews = reviewPage.items;
        _reviewPage = reviewPage.page == 0 ? page : reviewPage.page;
        _reviewTotalPages = reviewPage.totalPages;
        _reviewTotalCount = reviewPage.totalCount;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _reviewErrorMessage = formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loadingReviewPage = false);
      }
    }
  }

  Future<void> _loadPreviousReviews() => _loadReviewPage(_reviewPage - 1);

  Future<void> _loadNextReviews() => _loadReviewPage(_reviewPage + 1);

  Future<void> _openReader() async {
    final book = _book;
    if (book == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          book: book,
          session: widget.session,
          onNavigateToTab: widget.onNavigateToTab,
        ),
      ),
    );
  }

  Future<void> _openReview() async {
    final book = _book;
    if (book == null) {
      return;
    }

    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => ReviewDialog(book: book),
    );

    if (!mounted || submitted != true) {
      return;
    }

    showSuccessSnackBar(context, 'Your review was published successfully.');
    await _load();
  }

  Future<void> _addToCart() async {
    final book = _book;
    if (book == null) {
      return;
    }

    try {
      await widget.session.addToCart(book);
      if (!mounted) {
        return;
      }

      showSuccessSnackBar(
        context,
        'You successfully added the book to your shopping cart.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showDestructiveSnackBar(context, formatErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const CenteredLoadingIndicator()
            : _errorMessage != null
            ? _BookDetailErrorState(
                message: _errorMessage!,
                onBack: () => Navigator.of(context).pop(),
                onRetry: _load,
              )
            : _BookDetailContent(
                book: _book!,
                authorName: _authorName,
                averageRating: _averageRating,
                hasLibraryAccess: _hasLibraryAccess,
                reviews: _reviews,
                reviewPage: _reviewPage,
                reviewTotalPages: _reviewTotalPages,
                reviewTotalCount: _reviewTotalCount,
                loadingReviewPage: _loadingReviewPage,
                reviewErrorMessage: _reviewErrorMessage,
                onBack: () => Navigator.of(context).pop(),
                onAddToCart: _addToCart,
                onOpenReader: _openReader,
                onWriteReview: _openReview,
                onLoadPreviousReviews: _loadPreviousReviews,
                onLoadNextReviews: _loadNextReviews,
                onNavigateToTab: widget.onNavigateToTab,
              ),
      ),
    );
  }
}

class _BookDetailContent extends StatelessWidget {
  const _BookDetailContent({
    required this.book,
    required this.authorName,
    required this.averageRating,
    required this.hasLibraryAccess,
    required this.reviews,
    required this.reviewPage,
    required this.reviewTotalPages,
    required this.reviewTotalCount,
    required this.loadingReviewPage,
    required this.reviewErrorMessage,
    required this.onBack,
    required this.onAddToCart,
    required this.onOpenReader,
    required this.onWriteReview,
    required this.onLoadPreviousReviews,
    required this.onLoadNextReviews,
    required this.onNavigateToTab,
  });

  final BookModel book;
  final String authorName;
  final double averageRating;
  final bool hasLibraryAccess;
  final List<ReviewModel> reviews;
  final int reviewPage;
  final int reviewTotalPages;
  final int reviewTotalCount;
  final bool loadingReviewPage;
  final String? reviewErrorMessage;
  final VoidCallback onBack;
  final VoidCallback onAddToCart;
  final VoidCallback onOpenReader;
  final VoidCallback onWriteReview;
  final VoidCallback onLoadPreviousReviews;
  final VoidCallback onLoadNextReviews;
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final visibleReviewCount = reviewTotalCount == 0
        ? reviews.length
        : reviewTotalCount;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              InkWell(
                onTap: onBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      color: brandBlue,
                      size: 28,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Go Back',
                      style: TextStyle(
                        color: brandBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                child: BookCover(
                  imageUrl: book.imageLink,
                  width: 168,
                  height: 235,
                  radius: 0,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  book.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  authorName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarRow(rating: averageRating),
                      const SizedBox(width: 8),
                      Text(
                        averageRating > 0
                            ? averageRating.toStringAsFixed(1)
                            : 'No rating',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasLibraryAccess
                          ? const Color(0xFFE7F6EC)
                          : const Color(0xFFF1F5FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hasLibraryAccess
                          ? 'In Your Library'
                          : '\$${book.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasLibraryAccess
                            ? const Color(0xFF027A48)
                            : brandBlueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                book.description,
                style: TextStyle(
                  height: 1.8,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              if (hasLibraryAccess) ...[
                PrimaryPillButton(
                  label: 'Open Reader',
                  rectangular: true,
                  onPressed: onOpenReader,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onWriteReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandBlueDark,
                    side: const BorderSide(color: brandBlueDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Write a Review',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ] else
                PrimaryPillButton(
                  label: 'Add to Shopping',
                  rectangular: true,
                  onPressed: onAddToCart,
                ),
              const SizedBox(height: 28),
              Text(
                'REVIEWS${visibleReviewCount > 0 ? ' ($visibleReviewCount)' : ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (reviews.isEmpty)
                Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey.shade700),
                )
              else
                ...reviews.map((review) => _ReviewCard(review: review)),
              if (reviewErrorMessage != null) ...[
                const SizedBox(height: 10),
                FormMessage(message: reviewErrorMessage),
              ],
              if (reviewTotalPages > 1) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: loadingReviewPage || reviewPage <= 1
                          ? null
                          : onLoadPreviousReviews,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: brandBlueDark,
                    ),
                    if (loadingReviewPage)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    else
                      Text(
                        '$reviewPage / $reviewTotalPages',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    IconButton(
                      onPressed:
                          loadingReviewPage || reviewPage >= reviewTotalPages
                          ? null
                          : onLoadNextReviews,
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      color: brandBlueDark,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
        MobileBottomNavigation(
          currentIndex: 0,
          onTap: onNavigateToTab,
          embedded: true,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final createdAt = review.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRow(rating: review.rating.toDouble(), size: 18),
              if (createdAt != null) ...[
                const SizedBox(width: 10),
                Text(
                  DateFormat('d MMM yyyy').format(createdAt.toLocal()),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _BookDetailErrorState extends StatelessWidget {
  const _BookDetailErrorState({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: brandBlueDark, size: 52),
          const SizedBox(height: 16),
          const Text(
            'Unable to open this book right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          PrimaryPillButton(label: 'Try Again', onPressed: () => onRetry()),
          const SizedBox(height: 10),
          TextButton(onPressed: onBack, child: const Text('Go Back')),
        ],
      ),
    );
  }
}
