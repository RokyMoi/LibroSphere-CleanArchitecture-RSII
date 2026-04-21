import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../data/models/author_model.dart';
import '../../../../data/models/book_model.dart';
import '../../../../data/models/cart_item_input.dart';
import '../../../../data/models/genre_model.dart';
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
  AppServices get services => _services;
  final _uuid = const Uuid();
  final ValueNotifier<bool> _readyState = ValueNotifier(false);
  final ValueNotifier<AuthUserModel?> _profileState = ValueNotifier(null);
  final ValueNotifier<ShoppingCartModel?> _cartState = ValueNotifier(null);
  final ValueNotifier<int> _wishlistRevision = ValueNotifier(0);
  final ValueNotifier<int> _libraryRevision = ValueNotifier(0);

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

  final Map<String, double> _ratingCache = <String, double>{};
  _TimedCacheValue<List<BookModel>>? _recommendationsCache;
  _TimedCacheValue<List<LibraryEntry>>? _libraryCache;
  _TimedCacheValue<List<BookModel>>? _wishlistBooksCache;
  _TimedCacheValue<List<AuthorModel>>? _authorsCache;
  _TimedCacheValue<List<GenreModel>>? _genresCache;
  DateTime? _cartCachedAt;

  bool get isAuthenticated => tokens != null && currentUser != null;
  String? get accessToken => tokens?.accessToken;
  ValueListenable<bool> get readyState => _readyState;
  ValueListenable<AuthUserModel?> get profileState => _profileState;
  ValueListenable<ShoppingCartModel?> get cartState => _cartState;
  ValueListenable<int> get wishlistState => _wishlistRevision;
  ValueListenable<int> get libraryState => _libraryRevision;

  void _setReady(bool value) {
    isReady = value;
    _readyState.value = value;
  }

  void _setCurrentUser(AuthUserModel? user) {
    currentUser = user;
    _profileState.value = user;
  }

  void _setCart(ShoppingCartModel? nextCart, {bool notifySlice = true}) {
    cart = nextCart;
    if (notifySlice) {
      _cartState.value = nextCart;
    }
  }

  void _markWishlistChanged() {
    _wishlistRevision.value++;
  }

  void _markLibraryChanged() {
    _libraryRevision.value++;
  }

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

    _setReady(true);
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

  Future<Result<void>> requestPasswordReset(String email) {
    return _services.authRepository.requestPasswordReset(email);
  }

  Future<Result<void>> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _services.authRepository.resetPasswordWithCode(
      email: email,
      code: code,
      newPassword: newPassword,
    );
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
    if (accessToken != null) {
      await _services.authRepository.logout(accessToken!);
    }

    tokens = null;
    _setCurrentUser(null);
    _setCart(null);
    authorNames.clear();
    _resetCaches();
    _markWishlistChanged();
    _markLibraryChanged();
    await _services.storage.clearSession();
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _requireAuth();
    await _services.apiClient.updateProfile(accessToken!, firstName, lastName);
    _setCurrentUser(AuthUserModel(
      id: currentUser!.id,
      firstName: firstName,
      lastName: lastName,
      email: currentUser!.email,
      profilePictureUrl: currentUser!.profilePictureUrl,
    ));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _requireAuth();
    await _services.apiClient.changePassword(
      accessToken!,
      currentPassword,
      newPassword,
      confirmNewPassword,
    );
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    _requireAuth();
    return _services.apiClient.getOrders(accessToken!);
  }

  bool shouldRefreshLibrary() {
    return !_isFresh(_libraryCache, _userCollectionCacheTtl);
  }

  bool shouldRefreshCart() {
    final activeCartId = cart?.id ?? _services.storage.restoreCartId();
    if (accessToken == null || activeCartId == null) {
      return false;
    }

    if (cart == null) {
      return true;
    }

    if (_cartCachedAt == null) {
      return true;
    }

    return DateTime.now().difference(_cartCachedAt!) >= _userCollectionCacheTtl;
  }

  Future<void> refundOrder(String orderId) async {
    _requireAuth();
    await _services.apiClient.refundOrder(accessToken!, orderId);
  }

  Future<void> _applySession(AuthSessionModel session) async {
    _resetRuntimeState();
    tokens = session.tokens;
    _setCurrentUser(session.user);
    await _services.storage.persistTokens(session.tokens);
  }

  void _resetRuntimeState() {
    _setCart(null);
    _cartCachedAt = null;
    _setCurrentUser(null);
    authorNames.clear();
    _resetCaches();
    _markWishlistChanged();
    _markLibraryChanged();
  }

  void _resetCaches() {
    _bookCache.clear();
    _bookRequests.clear();
    _searchCache.clear();
    _reviewPageCache.clear();
    _ratingCache.clear();
    _recommendationsCache = null;
    _libraryCache = null;
    _wishlistBooksCache = null;
    _authorsCache = null;
    _genresCache = null;
    _cartCachedAt = null;
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
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? authorId,
    String? genreId,
    double? minPrice,
    double? maxPrice,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildFilterCacheKey(
      searchTerm: searchTerm,
      authorId: authorId,
      genreId: genreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    final cachedResult = _searchCache[cacheKey];
    if (!forceRefresh && _isFresh(cachedResult, _catalogCacheTtl)) {
      return cachedResult!.value;
    }

    final result = await _services.catalog.getBooks(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm?.trim(),
      authorId: authorId,
      genreId: genreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      accessToken: accessToken,
    );
    _primeBookCaches(result.items);
    _searchCache[cacheKey] = _TimedCacheValue(result);
    return result;
  }

  String _buildFilterCacheKey({
    String? searchTerm,
    String? authorId,
    String? genreId,
    double? minPrice,
    double? maxPrice,
  }) {
    final parts = <String>[
      searchTerm?.trim() ?? '',
      authorId ?? '',
      genreId ?? '',
      minPrice?.toString() ?? '',
      maxPrice?.toString() ?? '',
    ];
    return parts.join('|');
  }

  Future<HomeFeedModel> getHomeFeed({
    int page = 1,
    int pageSize = 8,
    int takeRecommendations = 4,
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
      page: page,
      pageSize: pageSize,
      takeRecommendations: takeRecommendations,
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

  Future<List<AuthorModel>> getAuthors({bool forceRefresh = false}) async {
    if (!forceRefresh && _isFresh(_authorsCache, _catalogCacheTtl)) {
      return _authorsCache!.value;
    }
    final authors = await _services.catalog.getAuthors();
    _authorsCache = _TimedCacheValue(authors);
    return authors;
  }

  Future<List<GenreModel>> getGenres({bool forceRefresh = false}) async {
    if (!forceRefresh && _isFresh(_genresCache, _catalogCacheTtl)) {
      return _genresCache!.value;
    }
    final genres = await _services.catalog.getGenres();
    _genresCache = _TimedCacheValue(genres);
    return genres;
  }

  Future<String> updateProfilePicture({
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    final url = await _services.apiClient.uploadProfilePicture(
      accessToken: accessToken!,
      imageBytes: imageBytes,
      filename: filename,
      contentType: contentType,
    );
    // Update current user with new profile picture URL
    if (currentUser != null) {
      _setCurrentUser(currentUser!.copyWith(profilePictureUrl: url));
    }
    return url;
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
      _setCart(null);
      _cartCachedAt = DateTime.now();
      await _services.storage.clearCart();
      _invalidateLibraryCache();
      _markLibraryChanged();
      return;
    }

    await _upsertCart(updatedItems);
  }

  Future<ShoppingCartModel?> refreshCart({bool forceRefresh = false}) async {
    final activeCartId = cart?.id ?? _services.storage.restoreCartId();
    if (activeCartId == null || accessToken == null) {
      return cart;
    }

    if (!forceRefresh &&
        cart != null &&
        _cartCachedAt != null &&
        DateTime.now().difference(_cartCachedAt!) < _userCollectionCacheTtl) {
      return cart;
    }

    try {
      _setCart(await _services.cart.getCart(accessToken!, activeCartId));
      _cartCachedAt = DateTime.now();
      if (cart!.books.isNotEmpty) {
        _primeBookCaches(cart!.books);
      }
      if (cart?.id != activeCartId) {
        await _services.storage.persistCartId(cart!.id);
      }
    } catch (_) {
      await _services.storage.clearCart();
      _setCart(null);
      _cartCachedAt = DateTime.now();
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
    _setCart(paymentCart);
    _cartCachedAt = DateTime.now();

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

    final paymentWasConfirmed =
        confirmedPaymentIntent.status == PaymentIntentsStatus.Succeeded ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.Processing ||
        confirmedPaymentIntent.status == PaymentIntentsStatus.RequiresCapture;
    if (!paymentWasConfirmed) {
      return await _services.orders.waitForPaidOrder(
        accessToken!,
        order.id,
        maxAttempts: 2,
      );
    }

    unawaited(_finalizeOrderSettlement(order.id));

    try {
      await _services.cart.deleteCart(accessToken!, paymentCart.id);
    } catch (_) {
      // Order flow can already consume the cart.
    }

    _setCart(null);
    _cartCachedAt = DateTime.now();
    await _services.storage.clearCart();
    _invalidateLibraryCache();
    _markLibraryChanged();
    return order;
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

  Future<void> _finalizeOrderSettlement(String orderId) async {
    final token = accessToken;
    if (token == null) {
      return;
    }

    try {
      final latestOrder = await _services.orders.waitForPaidOrder(
        token,
        orderId,
      );
      if (latestOrder.status == OrderStatus.paymentReceived) {
        _invalidateLibraryCache();
        _markLibraryChanged();
      }
    } catch (_) {
      // Checkout already succeeded from the user's perspective.
    }
  }

  Future<void> submitReview({
    required String bookId,
    required int rating,
    required String comment,
  }) async {
    _requireAuth();
    await _services.library.createReview(accessToken!, bookId, rating, comment);
    _reviewPageCache.removeWhere((key, _) => key.startsWith('$bookId::'));
    _ratingCache.remove(bookId);
    _markLibraryChanged();
  }

  Future<String> getReadUrl(String bookId) async {
    _requireAuth();
    return _services.library.getReadUrl(accessToken!, bookId);
  }

  Future<void> addToWishlist(String bookId) async {
    _requireAuth();
    await _services.wishlist.addToWishlist(accessToken!, bookId);
    _invalidateWishlistCache();
    _markWishlistChanged();
  }

  Future<void> removeFromWishlist(String bookId) async {
    _requireAuth();
    await _services.wishlist.removeFromWishlist(accessToken!, bookId);
    _invalidateWishlistCache();
    _markWishlistChanged();
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
    _markWishlistChanged();
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

    _setCart(newCart);
    _cartCachedAt = DateTime.now();
    await _services.storage.persistCartId(newCart.id);
    _invalidateSearchAndRecommendationCaches();
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

  @override
  void dispose() {
    _readyState.dispose();
    _profileState.dispose();
    _cartState.dispose();
    _wishlistRevision.dispose();
    _libraryRevision.dispose();
    super.dispose();
  }
}

class _TimedCacheValue<T> {
  _TimedCacheValue(this.value) : cachedAt = DateTime.now();

  final T value;
  final DateTime cachedAt;
}
