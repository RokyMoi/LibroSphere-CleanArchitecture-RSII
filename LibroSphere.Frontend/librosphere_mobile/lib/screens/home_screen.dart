import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/author_model.dart';
import '../data/models/book_model.dart';
import '../data/models/genre_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';
import '../widgets/filter_dialog.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key, required this.onOpenBook});

  final void Function(BookModel book) onOpenBook;

  @override
  State<MobileHomeScreen> createState() => MobileHomeScreenState();
}

class MobileHomeScreenState extends State<MobileHomeScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final Set<String> _prefetchedCoverUrls = <String>{};
  late Future<_HomeData> _future = _load();

  // Filter state
  String? _selectedAuthorId;
  String? _selectedAuthorName;
  String? _selectedGenreId;
  String? _selectedGenreName;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _hasActiveFilters =>
      _selectedAuthorId != null ||
      _selectedGenreId != null ||
      _minPrice != null ||
      _maxPrice != null;

  Future<_HomeData> _load([String? term, bool forceRefresh = false]) async {
    final session = SessionScope.read(context);
    final normalizedTerm = term?.trim();
    final isSearchMode = _hasActiveFilters || normalizedTerm?.isNotEmpty == true;

    if (isSearchMode) {
      final result = await session.getBooks(
        pageSize: 20,
        searchTerm: normalizedTerm,
        authorId: _selectedAuthorId,
        genreId: _selectedGenreId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        forceRefresh: forceRefresh,
      );

      return _HomeData(
        recommendations: const <BookModel>[],
        newest: result.items,
        searchTerm: normalizedTerm ?? '',
        totalCount: result.totalCount,
        hasActiveFilters: _hasActiveFilters,
        activeFilterDescription: _buildFilterDescription(),
        isSearchMode: true,
      );
    }

    final feed = await session.getHomeFeed(
      pageSize: 8,
      takeRecommendations: 5,
      searchTerm: normalizedTerm,
      forceRefresh: forceRefresh,
    );
    return _HomeData(
      recommendations: feed.recommendations,
      newest: feed.newest.items,
      searchTerm: normalizedTerm ?? '',
      totalCount: feed.newest.totalCount,
      hasActiveFilters: false,
      activeFilterDescription: null,
      isSearchMode: false,
    );
  }

  void _prefetchVisibleCovers(_HomeData data) {
    final urls = <String>{
      ...data.recommendations
          .take(data.isSearchMode ? 0 : 4)
          .map((book) => book.imageLink?.trim() ?? '')
          .where((url) => url.isNotEmpty),
      ...data.newest
          .take(data.isSearchMode ? 8 : 4)
          .map((book) => book.imageLink?.trim() ?? '')
          .where((url) => url.isNotEmpty),
    };

    if (urls.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_prefetchedCoverUrls.length > 120) {
        _prefetchedCoverUrls.clear();
      }

      for (final url in urls) {
        if (!_shouldPrefetchCoverUrl(url)) {
          continue;
        }

        if (!_prefetchedCoverUrls.add(url)) {
          continue;
        }

        unawaited(
          precacheImage(CachedNetworkImageProvider(url), context).catchError((
            _,
          ) {
            _prefetchedCoverUrls.remove(url);
          }),
        );
      }
    });
  }

  bool _shouldPrefetchCoverUrl(String url) {
    if (url.contains('X-Amz-Algorithm=')) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    return !uri.hasQuery;
  }

  String? _buildFilterDescription() {
    final parts = <String>[];
    if (_selectedAuthorName != null) {
      parts.add('Author: $_selectedAuthorName');
    }
    if (_selectedGenreName != null) {
      parts.add('Genre: $_selectedGenreName');
    }
    if (_minPrice != null || _maxPrice != null) {
      final min = _minPrice?.toStringAsFixed(0) ?? '0';
      final max = _maxPrice?.toStringAsFixed(0) ?? 'Any';
      parts.add('Price: \$$min - \$$max');
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  void _runSearch([String? rawValue]) {
    final value = (rawValue ?? _searchController.text).trim();
    setState(() {
      _future = _load(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _clearFilters();
  }

  void _clearFilters() {
    setState(() {
      _selectedAuthorId = null;
      _selectedAuthorName = null;
      _selectedGenreId = null;
      _selectedGenreName = null;
      _minPrice = null;
      _maxPrice = null;
      _future = _load();
    });
  }

  Future<void> _openFilterDialog() async {
    final session = SessionScope.read(context);
    final results = await Future.wait<Object>([
      session.getAuthors(),
      session.getGenres(),
    ]);
    final authors = results[0] as List<AuthorModel>;
    final genres = results[1] as List<GenreModel>;

    if (!mounted) return;

    final result = await showDialog<BookFilterResult>(
      context: context,
      builder: (context) => BookFilterDialog(
        authors: authors,
        genres: genres,
        initialAuthorId: _selectedAuthorId,
        initialGenreId: _selectedGenreId,
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAuthorId = result.authorId;
        _selectedAuthorName = result.authorName;
        _selectedGenreId = result.genreId;
        _selectedGenreName = result.genreName;
        _minPrice = result.minPrice;
        _maxPrice = result.maxPrice;
        _future = _load(_searchController.text);
      });
    }
  }

  Future<void> refreshIfStale() async {
    final session = SessionScope.read(context);
    if (!session.shouldRefreshCatalog(
      searchTerm: _searchController.text,
      authorId: _selectedAuthorId,
      genreId: _selectedGenreId,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      includeRecommendations:
          _searchController.text.trim().isEmpty && !_hasActiveFilters,
    )) {
      return;
    }

    final nextFuture = _load(_searchController.text, true);
    if (!mounted) {
      return;
    }

    setState(() {
      _future = nextFuture;
    });
    await nextFuture;
  }

  Future<void> _refresh() async {
    final newFuture = _load(_searchController.text, true);
    setState(() {
      _future = newFuture;
    });
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
            return const HomeSkeleton();
          }

          final data = snapshot.data!;
          final session = SessionScope.read(context);
          _prefetchVisibleCovers(data);
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SearchBarCard(
                            controller: _searchController,
                            onSubmitted: _runSearch,
                            onClear: _clearSearch,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _hasActiveFilters ? brandBlueDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: brandBlueDark, width: 1),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: _hasActiveFilters
                                  ? Colors.white
                                  : brandBlueDark,
                            ),
                            onPressed: _openFilterDialog,
                          ),
                        ),
                      ],
                    ),
                    if (data.searchTerm.isNotEmpty || data.hasActiveFilters) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Found ${data.totalCount} book${data.totalCount == 1 ? '' : 's'}${data.searchTerm.isNotEmpty ? ' for "${data.searchTerm}"' : ''}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (data.activeFilterDescription != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Filters: ${data.activeFilterDescription}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: data.hasActiveFilters
                                ? _clearFilters
                                : _clearSearch,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                    if (data.isSearchMode && data.newest.isEmpty) ...[
                      const SizedBox(height: 18),
                      _NoSearchResults(
                        searchTerm: data.searchTerm,
                        activeFilterDescription: data.activeFilterDescription,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (!data.isSearchMode && data.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const Text(
                        'Recommended Books',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
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
                                      session.authorNameForBook(book),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
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
                    Text(
                      data.isSearchMode ? 'Search Results' : 'Newest',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = data.newest[index];
                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: NewestBookTile(
                            book: book,
                            authorName: session.authorNameForBook(book),
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
                      );
                    },
                    childCount: data.newest.length,
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
    required this.totalCount,
    required this.hasActiveFilters,
    required this.isSearchMode,
    this.activeFilterDescription,
  });

  final List<BookModel> recommendations;
  final List<BookModel> newest;
  final String searchTerm;
  final int totalCount;
  final bool hasActiveFilters;
  final bool isSearchMode;
  final String? activeFilterDescription;
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({
    required this.searchTerm,
    this.activeFilterDescription,
  });

  final String searchTerm;
  final String? activeFilterDescription;

  @override
  Widget build(BuildContext context) {
    final hasSearchTerm = searchTerm.trim().isNotEmpty;
    final title = hasSearchTerm
        ? 'No books found for "$searchTerm".'
        : 'No books found for the selected filters.';
    final subtitle = hasSearchTerm
        ? 'Try another title, author, or a shorter keyword.'
        : activeFilterDescription == null
        ? 'Try widening the filters and refresh the list.'
        : 'Current filters: $activeFilterDescription';

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
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
