import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/models/cart_item_input.dart';
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

  final AppServices _services;
  final _uuid = const Uuid();

  bool isReady = false;
  AuthTokensModel? tokens;
  AuthUserModel? currentUser;
  ShoppingCartModel? cart;
  final Map<String, String> authorNames = <String, String>{};
  final Map<String, BookModel> _bookCache = <String, BookModel>{};
  final Map<String, Future<BookModel>> _bookRequests = <String, Future<BookModel>>{};
  final Map<String, PagedResult<BookModel>> _searchCache = <String, PagedResult<BookModel>>{};
  final Map<String, PagedResult<ReviewModel>> _reviewPageCache = <String, PagedResult<ReviewModel>>{};
  final Map<String, List<ReviewModel>> _reviewCache = <String, List<ReviewModel>>{};
  final Map<String, double> _ratingCache = <String, double>{};
  Future<void>? _authorsFuture;
  List<BookModel>? _recommendationsCache;
  List<LibraryEntry>? _libraryCache;
  List<BookModel>? _wishlistBooksCache;

  bool get isAuthenticated => tokens != null && currentUser != null;
  String? get accessToken => tokens?.accessToken;

  Future<void> initialize() async {
    final restoredTokens = _services.storage.restoreTokens();

    if (restoredTokens != null) {
      final result = await _services.authRepository.restoreSession(restoredTokens);
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

  Future<void> ensureAuthors() async {
    if (authorNames.isNotEmpty) {
      return;
    }

    if (_authorsFuture != null) {
      await _authorsFuture;
      return;
    }

    _authorsFuture = _loadAuthors();
    await _authorsFuture;
  }

  String authorName(String authorId) => authorNames[authorId] ?? 'Unknown Author';

  Future<void> logout() async {
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
    _resetRuntimeState();
    tokens = session.tokens;
    currentUser = session.user;
    await _services.storage.persistTokens(session.tokens);
    await ensureAuthors();
    await _restoreCart();
    notifyListeners();
  }

  Future<void> _restoreCart() async {
    final cartId = _services.storage.restoreCartId();
    if (cartId == null || accessToken == null) {
      return;
    }

    try {
      cart = await _services.cart.getCart(accessToken!, cartId);
    } catch (_) {
      await _services.storage.clearCart();
      cart = null;
    }
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await _services.catalog.getAuthors();
      authorNames.addAll({for (final author in authors) author.id: author.name});
    } catch (_) {
      // Keep UI usable even if author lookup fails.
    } finally {
      _authorsFuture = null;
    }
  }

  void _resetRuntimeState() {
    cart = null;
    currentUser = null;
    authorNames.clear();
    _resetCaches();
  }

  void _resetCaches() {
    _authorsFuture = null;
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

    return reviews.map((review) => review.rating).reduce((a, b) => a + b) / reviews.length;
  }

  String _reviewPageCacheKey(String bookId, int page, int pageSize) => '$bookId::$page::$pageSize';

  Future<PagedResult<BookModel>> getBooks({String? searchTerm}) async {
    await ensureAuthors();
    final normalizedTerm = searchTerm?.trim() ?? '';
    if (_searchCache.containsKey(normalizedTerm)) {
      return _searchCache[normalizedTerm]!;
    }

    final result = await _services.catalog.getBooks(
      searchTerm: normalizedTerm.isEmpty ? null : normalizedTerm,
      accessToken: accessToken,
    );
    _searchCache[normalizedTerm] = result;
    return result;
  }

  Future<List<BookModel>> getRecommendations(List<BookModel> fallbackBooks) async {
    if (!isAuthenticated) {
      return fallbackBooks.take(3).toList();
    }

    if (_recommendationsCache != null) {
      return _recommendationsCache!;
    }

    final recommendations = await _services.catalog.getRecommendations(accessToken!);
    _recommendationsCache = recommendations;
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

  Future<Map<String, double>> getAverageRatings(Iterable<String> bookIds) async {
    final uniqueIds = bookIds.toSet();
    await Future.wait(uniqueIds.map(getAverageRating));
    return {
      for (final bookId in uniqueIds) bookId: _ratingCache[bookId] ?? 0,
    };
  }

  Future<void> addToCart(BookModel book) async {
    _requireAuth();
    final existingItems = List<CartItemInput>.from(cart?.items ?? <CartItemInput>[]);
    if (existingItems.any((item) => item.bookId == book.id)) {
      return;
    }

    existingItems.add(CartItemInput(bookId: book.id, amount: book.amount, currencyCode: book.currency));
    await _upsertCart(existingItems);
  }

  Future<void> removeFromCart(String bookId) async {
    if (cart == null || accessToken == null) {
      return;
    }

    final updatedItems = cart!.items.where((item) => item.bookId != bookId).toList();
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
    if (cart == null || accessToken == null) {
      return cart;
    }

    cart = await _services.cart.getCart(accessToken!, cart!.id);
    notifyListeners();
    return cart;
  }

  Future<OrderModel> checkout(BillingDetails billingDetails) async {
    _requireAuth();
    if (cart == null) {
      throw Exception('Shopping cart is empty.');
    }

    final paymentCart = await _services.cart.createPaymentIntent(accessToken!, cart!.id);
    cart = paymentCart;
    notifyListeners();

    final order = await _services.orders.createOrder(accessToken!, paymentCart.id);

    final confirmedPaymentIntent = await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: paymentCart.clientSecret ?? order.clientSecret ?? '',
      data: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(billingDetails: billingDetails),
      ),
    );

    final latestOrder = await _services.orders.waitForPaidOrder(accessToken!, order.id);
    final paymentWasConfirmed = confirmedPaymentIntent.status == PaymentIntentsStatus.Succeeded ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.Processing ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.RequiresCapture;
    final shouldClearCart = paymentWasConfirmed || latestOrder.status == OrderStatus.paymentReceived;

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

  Future<List<LibraryEntry>> getLibraryEntries() async {
    _requireAuth();
    if (_libraryCache != null) {
      return _libraryCache!;
    }

    final page = await _services.library.getLibrary(accessToken!);
    _libraryCache = page.items;
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
  }

  Future<void> removeFromWishlist(String bookId) async {
    _requireAuth();
    await _services.wishlist.removeFromWishlist(accessToken!, bookId);
    _invalidateWishlistCache();
  }

  Future<List<BookModel>> getWishlistBooks() async {
    _requireAuth();
    if (_wishlistBooksCache != null) {
      return _wishlistBooksCache!;
    }

    final wishlist = await _services.wishlist.getWishlist(accessToken!);
    final books = await Future.wait(wishlist.items.map((item) => getBook(item.bookId)));
    _wishlistBooksCache = books;
    return books;
  }

  Future<void> moveWishlistBookToCart(BookModel book) async {
    _requireAuth();
    await addToCart(book);
    await _services.wishlist.removeFromWishlist(accessToken!, book.id);
    _invalidateWishlistCache();
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
}
