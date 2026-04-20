import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/models/cart_item_input.dart';
import '../../../../data/models/home_feed_model.dart';
import '../../../../data/models/library_entry.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/order_status.dart';
import '../../../../data/models/paged_result.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/models/shopping_cart_model.dart';
import '../../../../features/auth/data/models/auth_session_model.dart';
import '../../../../features/auth/data/models/auth_tokens_model.dart';
import '../../../../features/auth/data/models/auth_user_model.dart';
import '../../../../features/auth/data/models/login_request.dart';
import '../../../../features/auth/data/models/register_request.dart';
import '../../../../services/app_services.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._services);

  static const _catalogCacheTtl = Duration(seconds: 15);
  static const _recommendationsCacheTtl = Duration(seconds: 20);
  static const _userCollectionCacheTtl = Duration(seconds: 10);

  final AppServices _services;
  final _uuid = const Uuid();

  bool isReady = false;
  AuthTokensModel? tokens;
  AuthUserModel? currentUser;
  ShoppingCartModel? cart;
  final Map<String, String> authorNames = <String, String>{};
  final Map<String, BookModel> _bookCache = <String, BookModel>{};
  final Map<String, Future<BookModel>> _bookRequests =
      <String, Future<BookModel>>{};
  final Map<String, _TimedCacheValue<PagedResult<BookModel>>> _searchCache =
      <String, _TimedCacheValue<PagedResult<BookModel>>>{};
  final Map<String, PagedResult<ReviewModel>> _reviewPageCache =
      <String, PagedResult<ReviewModel>>{};
  final Map<String, List<ReviewModel>> _reviewCache =
      <String, List<ReviewModel>>{};
  final Map<String, double> _ratingCache = <String, double>{};
  _TimedCacheValue<List<BookModel>>? _recommendationsCache;
  _TimedCacheValue<List<LibraryEntry>>? _libraryCache;
  _TimedCacheValue<List<BookModel>>? _wishlistBooksCache;
  int _sessionBootstrapVersion = 0;

  bool get isAuthenticated => tokens != null && currentUser != null;
  String? get accessToken => tokens?.accessToken;

  Future<void> initialize() async {
    final restoredTokens = _services.storage.restoreTokens();

    if (restoredTokens != null) {
      final result = await _services.authRepository.restoreSession(
        restoredTokens,
      );
      switch (result) {
        case Success<AuthSessionModel>(value: final session):
          await _applySession(session);
        case ErrorResult<AuthSessionModel>():
          await logout();
      }
    }

    isReady = true;
    notifyListeners();
  }

  Future<Result<void>> login(String email, String password) async {
    final result = await _services.authRepository.login(
      LoginRequest(email: email, password: password),
    );

    switch (result) {
      case Success<AuthSessionModel>(value: final session):
        await _applySession(session);
        return const Success<void>(null);
      case ErrorResult<AuthSessionModel>(failure: final failure):
        return ErrorResult(failure);
    }
  }

  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final result = await _services.authRepository.register(
      RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      ),
    );

    switch (result) {
      case Success<AuthSessionModel>(value: final session):
        await _applySession(session);
        return const Success<void>(null);
      case ErrorResult<AuthSessionModel>(failure: final failure):
        return ErrorResult(failure);
    }
  }

  String authorName(String authorId) =>
      authorNames[authorId] ?? 'Unknown Author';

  String authorNameForBook(BookModel book) {
    if (book.authorName.trim().isNotEmpty) {
      return book.authorName.trim();
    }

    return authorName(book.authorId);
  }

  Future<void> logout() async {
    _sessionBootstrapVersion++;
    if (accessToken != null) {
      await _services.authRepository.logout(accessToken!);
    }

    tokens = null;
    currentUser = null;
    cart = null;
    authorNames.clear();
    _resetCaches();
    await _services.storage.clearSession();
    notifyListeners();
  }

  Future<void> _applySession(AuthSessionModel session) async {
    final bootstrapVersion = ++_sessionBootstrapVersion;
    _resetRuntimeState();
    tokens = session.tokens;
    currentUser = session.user;
    await _services.storage.persistTokens(session.tokens);
    notifyListeners();
    unawaited(_hydrateSessionState(bootstrapVersion));
  }

  Future<void> _hydrateSessionState(int bootstrapVersion) async {
    if (bootstrapVersion != _sessionBootstrapVersion || !isAuthenticated) {
      return;
    }

    notifyListeners();
  }

  void _resetRuntimeState() {
    cart = null;
    currentUser = null;
    authorNames.clear();
    _resetCaches();
  }

  void _resetCaches() {
    _bookCache.clear();
    _bookRequests.clear();
    _searchCache.clear();
    _reviewPageCache.clear();
    _reviewCache.clear();
    _ratingCache.clear();
    _recommendationsCache = null;
    _libraryCache = null;
    _wishlistBooksCache = null;
  }

  void _invalidateWishlistCache() {
    _wishlistBooksCache = null;
  }

  void _invalidateLibraryCache() {
    _libraryCache = null;
  }

  void _invalidateSearchAndRecommendationCaches() {
    _searchCache.clear();
    _recommendationsCache = null;
  }

  void _requireAuth() {
    if (!isAuthenticated) {
      throw Exception('Please login first.');
    }
  }

  double _calculateAverageRating(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return 0;
    }

    return reviews.map((review) => review.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  String _reviewPageCacheKey(String bookId, int page, int pageSize) =>
      '$bookId::$page::$pageSize';

  bool shouldRefreshCatalog({String? searchTerm}) {
    final normalizedTerm = searchTerm?.trim() ?? '';
    final searchCache = _searchCache[normalizedTerm];
    if (!_isFresh(searchCache, _catalogCacheTtl)) {
      return true;
    }

    return isAuthenticated &&
        !_isFresh(_recommendationsCache, _recommendationsCacheTtl);
  }

  Future<PagedResult<BookModel>> getBooks({
    String? searchTerm,
    bool forceRefresh = false,
  }) async {
    final normalizedTerm = searchTerm?.trim() ?? '';
    final cachedResult = _searchCache[normalizedTerm];
    if (!forceRefresh && _isFresh(cachedResult, _catalogCacheTtl)) {
      return cachedResult!.value;
    }

    final result = await _services.catalog.getBooks(
      searchTerm: normalizedTerm.isEmpty ? null : normalizedTerm,
      accessToken: accessToken,
    );
    _primeBookCaches(result.items);
    _searchCache[normalizedTerm] = _TimedCacheValue(result);
    return result;
  }

  Future<HomeFeedModel> getHomeFeed({
    String? searchTerm,
    bool forceRefresh = false,
  }) async {
    final normalizedTerm = searchTerm?.trim() ?? '';
    final cachedBooks = _searchCache[normalizedTerm];
    final cachedRecommendations = _recommendationsCache;
    final hasFreshCatalog = _isFresh(cachedBooks, _catalogCacheTtl);
    final hasFreshRecommendations =
        !isAuthenticated ||
        _isFresh(cachedRecommendations, _recommendationsCacheTtl);

    if (!forceRefresh && hasFreshCatalog && hasFreshRecommendations) {
      return HomeFeedModel(
        newest: cachedBooks!.value,
        recommendations: isAuthenticated
            ? cachedRecommendations!.value
            : cachedBooks.value.items.take(3).toList(),
      );
    }

    final feed = await _services.catalog.getHomeFeed(
      searchTerm: normalizedTerm.isEmpty ? null : normalizedTerm,
      accessToken: accessToken,
    );

    _primeBookCaches(feed.newest.items);
    _searchCache[normalizedTerm] = _TimedCacheValue(feed.newest);

    if (isAuthenticated) {
      _primeBookCaches(feed.recommendations);
      _recommendationsCache = _TimedCacheValue(feed.recommendations);
    }

    return feed;
  }

  Future<List<BookModel>> getRecommendations(
    List<BookModel> fallbackBooks, {
    bool forceRefresh = false,
  }) async {
    if (!isAuthenticated) {
      return fallbackBooks.take(3).toList();
    }

    if (!forceRefresh &&
        _isFresh(_recommendationsCache, _recommendationsCacheTtl)) {
      return _recommendationsCache!.value;
    }

    final recommendations = await _services.catalog.getRecommendations(
      accessToken!,
    );
    _primeBookCaches(recommendations);
    _recommendationsCache = _TimedCacheValue(recommendations);
    return recommendations;
  }

  Future<BookModel> getBook(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _bookCache.containsKey(id)) {
      return _bookCache[id]!;
    }

    if (!forceRefresh && _bookRequests.containsKey(id)) {
      return _bookRequests[id]!;
    }

    final request = _services.catalog.getBook(id, accessToken: accessToken);
    _bookRequests[id] = request;

    try {
      final book = await request;
      _bookCache[id] = book;
      _ratingCache[id] = book.averageRating;
      if (book.authorName.trim().isNotEmpty) {
        authorNames[book.authorId] = book.authorName.trim();
      }
      return book;
    } finally {
      _bookRequests.remove(id);
    }
  }

  Future<PagedResult<ReviewModel>> getReviewPage(
    String bookId, {
    int page = 1,
    int pageSize = 3,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _reviewPageCacheKey(bookId, page, pageSize);
    if (!forceRefresh && _reviewPageCache.containsKey(cacheKey)) {
      return _reviewPageCache[cacheKey]!;
    }

    final result = await _services.catalog.getReviews(
      bookId,
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
    );
    _reviewPageCache[cacheKey] = result;
    return result;
  }

  Future<List<ReviewModel>> getReviews(
    String bookId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _reviewCache.containsKey(bookId)) {
      return _reviewCache[bookId]!;
    }

    final reviews = <ReviewModel>[];
    var pageNumber = 1;

    while (true) {
      final page = await getReviewPage(
        bookId,
        page: pageNumber,
        pageSize: 20,
        forceRefresh: forceRefresh,
      );
      reviews.addAll(page.items);
      if (!page.hasNextPage) {
        break;
      }
      pageNumber++;
    }

    _reviewCache[bookId] = reviews;
    _ratingCache[bookId] = _calculateAverageRating(reviews);
    return reviews;
  }

  Future<double> getAverageRating(String bookId) async {
    if (_ratingCache.containsKey(bookId)) {
      return _ratingCache[bookId]!;
    }

    final reviews = await getReviews(bookId);
    final average = _calculateAverageRating(reviews);
    _ratingCache[bookId] = average;
    return average;
  }

  Future<Map<String, double>> getAverageRatings(
    Iterable<String> bookIds,
  ) async {
    final uniqueIds = bookIds.toSet();
    await Future.wait(uniqueIds.map(getAverageRating));
    return {for (final bookId in uniqueIds) bookId: _ratingCache[bookId] ?? 0};
  }

  Future<void> addToCart(BookModel book) async {
    _requireAuth();
    await refreshCart();
    final existingItems = List<CartItemInput>.from(
      cart?.items ?? <CartItemInput>[],
    );
    if (existingItems.any((item) => item.bookId == book.id)) {
      return;
    }

    existingItems.add(
      CartItemInput(
        bookId: book.id,
        amount: book.amount,
        currencyCode: book.currency,
      ),
    );
    await _upsertCart(existingItems);
  }

  Future<void> removeFromCart(String bookId) async {
    await refreshCart();
    if (cart == null || accessToken == null) {
      return;
    }

    final updatedItems = cart!.items
        .where((item) => item.bookId != bookId)
        .toList();
    if (updatedItems.isEmpty) {
      await _services.cart.deleteCart(accessToken!, cart!.id);
      cart = null;
      await _services.storage.clearCart();
      _invalidateLibraryCache();
      notifyListeners();
      return;
    }

    await _upsertCart(updatedItems);
  }

  Future<ShoppingCartModel?> refreshCart() async {
    final activeCartId = cart?.id ?? _services.storage.restoreCartId();
    if (activeCartId == null || accessToken == null) {
      return cart;
    }

    try {
      cart = await _services.cart.getCart(accessToken!, activeCartId);
      if (cart?.id != activeCartId) {
        await _services.storage.persistCartId(cart!.id);
      }
      notifyListeners();
    } catch (_) {
      await _services.storage.clearCart();
      cart = null;
      notifyListeners();
    }
    return cart;
  }

  Future<OrderModel> checkout(BillingDetails billingDetails) async {
    _requireAuth();
    if (cart == null) {
      throw Exception('Shopping cart is empty.');
    }

    final paymentCart = await _services.cart.createPaymentIntent(
      accessToken!,
      cart!.id,
    );
    cart = paymentCart;
    notifyListeners();

    final order = await _services.orders.createOrder(
      accessToken!,
      paymentCart.id,
    );

    final confirmedPaymentIntent = await Stripe.instance.confirmPayment(
      paymentIntentClientSecret:
          paymentCart.clientSecret ?? order.clientSecret ?? '',
      data: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
      ),
    );

    final latestOrder = await _services.orders.waitForPaidOrder(
      accessToken!,
      order.id,
    );
    final paymentWasConfirmed =
        confirmedPaymentIntent.status == PaymentIntentsStatus.Succeeded ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.Processing ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.RequiresCapture;
    final shouldClearCart =
        paymentWasConfirmed ||
        latestOrder.status == OrderStatus.paymentReceived;

    if (!shouldClearCart) {
      return latestOrder;
    }

    try {
      await _services.cart.deleteCart(accessToken!, paymentCart.id);
    } catch (_) {
      // Order flow can already consume the cart.
    }

    cart = null;
    await _services.storage.clearCart();
    _invalidateLibraryCache();
    notifyListeners();
    return latestOrder;
  }

  Future<List<LibraryEntry>> getLibraryEntries({
    bool forceRefresh = false,
  }) async {
    _requireAuth();
    if (!forceRefresh && _isFresh(_libraryCache, _userCollectionCacheTtl)) {
      return _libraryCache!.value;
    }

    final page = await _services.library.getLibrary(accessToken!);
    _primeBookCaches(page.items.map((entry) => entry.toBookModel()));
    _libraryCache = _TimedCacheValue(page.items);
    return page.items;
  }

  Future<bool> hasLibraryAccess(String bookId) async {
    if (!isAuthenticated) {
      return false;
    }

    final entries = await getLibraryEntries();
    return entries.any((entry) => entry.bookId == bookId);
  }

  Future<void> submitReview({
    required String bookId,
    required int rating,
    required String comment,
  }) async {
    _requireAuth();
    await _services.library.createReview(accessToken!, bookId, rating, comment);
    _reviewPageCache.removeWhere((key, _) => key.startsWith('$bookId::'));
    _reviewCache.remove(bookId);
    _ratingCache.remove(bookId);
  }

  Future<String> getReadUrl(String bookId) async {
    _requireAuth();
    return _services.library.getReadUrl(accessToken!, bookId);
  }

  Future<void> addToWishlist(String bookId) async {
    _requireAuth();
    await _services.wishlist.addToWishlist(accessToken!, bookId);
    _invalidateWishlistCache();
    notifyListeners();
  }

  Future<void> removeFromWishlist(String bookId) async {
    _requireAuth();
    await _services.wishlist.removeFromWishlist(accessToken!, bookId);
    _invalidateWishlistCache();
    notifyListeners();
  }

  Future<List<BookModel>> getWishlistBooks() async {
    _requireAuth();
    if (_isFresh(_wishlistBooksCache, _userCollectionCacheTtl)) {
      return _wishlistBooksCache!.value;
    }

    final wishlist = await _services.wishlist.getWishlist(accessToken!);
    final books = wishlist.items.map((item) => item.toBookModel()).toList();
    _primeBookCaches(books);
    _wishlistBooksCache = _TimedCacheValue(books);
    return books;
  }

  Future<void> moveWishlistBookToCart(BookModel book) async {
    _requireAuth();
    await addToCart(book);
    await _services.wishlist.removeFromWishlist(accessToken!, book.id);
    _invalidateWishlistCache();
    notifyListeners();
  }

  Future<void> _upsertCart(List<CartItemInput> items) async {
    _requireAuth();
    final cartId = cart?.id ?? _uuid.v4();
    final newCart = await _services.cart.upsertCart(
      accessToken: accessToken!,
      cartId: cartId,
      userId: currentUser!.id,
      items: items,
      clientSecret: cart?.clientSecret,
      paymentIntentId: cart?.paymentIntentId,
    );

    cart = newCart;
    await _services.storage.persistCartId(newCart.id);
    _invalidateSearchAndRecommendationCaches();
    notifyListeners();
  }

  bool _isFresh<T>(_TimedCacheValue<T>? entry, Duration ttl) {
    if (entry == null) {
      return false;
    }

    return DateTime.now().difference(entry.cachedAt) < ttl;
  }

  void _primeBookCaches(Iterable<BookModel> books) {
    for (final book in books) {
      _bookCache[book.id] = book;
      _ratingCache[book.id] = book.averageRating;
      if (book.authorName.trim().isNotEmpty) {
        authorNames[book.authorId] = book.authorName.trim();
      }
    }
  }
}

class _TimedCacheValue<T> {
  _TimedCacheValue(this.value) : cachedAt = DateTime.now();

  final T value;
  final DateTime cachedAt;
}
