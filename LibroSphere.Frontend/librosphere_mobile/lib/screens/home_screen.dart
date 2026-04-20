import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key, required this.onOpenBook});

  final void Function(BookModel book) onOpenBook;

  @override
  State<MobileHomeScreen> createState() => MobileHomeScreenState();
}

class MobileHomeScreenState extends State<MobileHomeScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  late Future<_HomeData> _future = _load();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<_HomeData> _load([String? term, bool forceRefresh = false]) async {
    final session = SessionScope.read(context);
    final normalizedTerm = term?.trim();
    final feed = await session.getHomeFeed(
      searchTerm: normalizedTerm,
      forceRefresh: forceRefresh,
    );
    return _HomeData(
      recommendations: feed.recommendations,
      newest: feed.newest.items,
      searchTerm: normalizedTerm ?? '',
    );
  }

  void _runSearch([String? rawValue]) {
    final value = (rawValue ?? _searchController.text).trim();
    setState(() {
      _future = _load(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _future = _load();
    });
  }

  Future<void> refreshIfStale() async {
    final session = SessionScope.read(context);
    if (!session.shouldRefreshCatalog(searchTerm: _searchController.text)) {
      return;
    }

    final nextFuture = _load(_searchController.text, true);
    if (!mounted) {
      return;
    }

    setState(() => _future = nextFuture);
    await nextFuture;
  }

  Future<void> _refresh() async {
    final newFuture = _load(_searchController.text, true);
    setState(() => _future = newFuture);
    await newFuture;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshIfStale());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return InfoStateView(
              title: 'Home',
              message: formatErrorMessage(snapshot.error!),
              icon: Icons.home_outlined,
            );
          }

          if (!snapshot.hasData) {
            return const CenteredLoadingIndicator();
          }

          final data = snapshot.data!;
          final session = context.session;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              SearchBarCard(
                controller: _searchController,
                onSubmitted: _runSearch,
                onClear: _clearSearch,
              ),
              if (data.searchTerm.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Results for "${data.searchTerm}"',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
              if (data.searchTerm.isNotEmpty && data.newest.isEmpty) ...[
                const SizedBox(height: 18),
                _NoSearchResults(searchTerm: data.searchTerm),
                const SizedBox(height: 24),
              ],
              if (data.recommendations.isNotEmpty) ...[
                const SizedBox(height: 26),
                const Text(
                  'Recommended Books',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.recommendations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final book = data.recommendations[index];
                      return GestureDetector(
                        onTap: () => widget.onOpenBook(book),
                        child: SizedBox(
                          width: 96,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BookCover(
                                imageUrl: book.imageLink,
                                width: 96,
                                height: 118,
                                radius: 2,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                session.authorName(book.authorId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const Text(
                'Newest',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...data.newest
                  .take(6)
                  .map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: NewestBookTile(
                        book: book,
                        authorName: session.authorName(book.authorId),
                        rating: book.averageRating,
                        onOpen: () => widget.onOpenBook(book),
                        onWishlist: () async {
                          try {
                            await session.addToWishlist(book.id);
                            if (!context.mounted) return;
                            showSuccessSnackBar(context, 'Saved to wishlist.');
                          } catch (error) {
                            if (!context.mounted) return;
                            showDestructiveSnackBar(
                              context,
                              formatErrorMessage(error),
                            );
                          }
                        },
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeData {
  _HomeData({
    required this.recommendations,
    required this.newest,
    required this.searchTerm,
  });

  final List<BookModel> recommendations;
  final List<BookModel> newest;
  final String searchTerm;
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.searchTerm});

  final String searchTerm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 42, color: brandBlueDark),
          const SizedBox(height: 10),
          Text(
            'No books found for "$searchTerm".',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another title, author, or a shorter keyword.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
