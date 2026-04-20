import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/models/json_helpers.dart';
import '../../data/models/author_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/cart_item_input.dart';
import '../../data/models/home_feed_model.dart';
import '../../data/models/library_entry.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/models/paged_result.dart';
import '../../data/models/review_model.dart';
import '../../data/models/shopping_cart_model.dart';
import '../../data/models/wishlist_model.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';

class ApiClient {
  static const _requestTimeout = Duration(seconds: 12);
  final String _baseUrl = resolveApiBaseUrl();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final response = await _post(
      '/api/auth/register',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );

    return _decodeMap(response);
  }

  Future<void> logout(String accessToken) async {
    await _post('/api/auth/logout', token: accessToken);
  }

  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final response = await _get('/api/user/me', token: accessToken);
    return _decodeMap(response);
  }

  Future<String?> getStripePublishableKey() async {
    final response = await _get('/api/payment/config');
    final value = readString(_decodeMap(response), [
      'publishableKey',
      'PublishableKey',
    ]);
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<List<AuthorModel>> getAuthors() async {
    final response = await _get('/api/author?page=1&pageSize=200');
    final items = _decodeItems(_decodeMap(response));
    return items.map(AuthorModel.fromJson).toList();
  }

  Future<PagedResult<BookModel>> getBooks({
    String? searchTerm,
    String? accessToken,
  }) async {
    final response = await _send(() {
      return http.get(
        _uri(
          '/api/book',
          query: {
            'page': '1',
            'pageSize': '20',
            if (searchTerm != null && searchTerm.trim().isNotEmpty)
              'searchTerm': searchTerm.trim(),
          },
        ),
        headers: _headers(token: accessToken),
      );
    });

    return PagedResult<BookModel>.fromJson(
      _decodeMap(response),
      (item) => BookModel.fromJson(item),
    );
  }

  Future<HomeFeedModel> getHomeFeed({
    String? searchTerm,
    String? accessToken,
  }) async {
    final response = await _send(() {
      return http.get(
        _uri(
          '/api/book/home',
          query: {
            'page': '1',
            'pageSize': '20',
            'takeRecommendations': '5',
            if (searchTerm != null && searchTerm.trim().isNotEmpty)
              'searchTerm': searchTerm.trim(),
          },
        ),
        headers: _headers(token: accessToken),
      );
    });

    final json = _decodeMap(response);
    final newest = PagedResult<BookModel>(
      items: _decodeArray(json, 'newest').map(BookModel.fromJson).toList(),
      page: readInt(json, ['page', 'Page']),
      pageSize: readInt(json, ['pageSize', 'PageSize']),
      totalCount: readInt(json, ['totalCount', 'TotalCount']),
    );
    final recommendations = _decodeArray(
      json,
      'recommendations',
    ).map(BookModel.fromJson).toList();

    return HomeFeedModel(newest: newest, recommendations: recommendations);
  }

  Future<BookModel> getBook(String bookId, String? accessToken) async {
    final response = await _get('/api/book/$bookId', token: accessToken);
    return BookModel.fromJson(_decodeMap(response));
  }

  Future<List<BookModel>> getRecommendations(String accessToken) async {
    final response = await _get(
      '/api/recommendations?take=5',
      token: accessToken,
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return <BookModel>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromJson)
        .toList();
  }

  Future<PagedResult<LibraryEntry>> getLibrary(String accessToken) async {
    final response = await _get(
      '/api/library?page=1&pageSize=20',
      token: accessToken,
    );
    return PagedResult<LibraryEntry>.fromJson(
      _decodeMap(response),
      (item) => LibraryEntry.fromJson(item),
    );
  }

  Future<String> getReadUrl(String accessToken, String bookId) async {
    final response = await _get(
      '/api/library/$bookId/read',
      token: accessToken,
    );
    return readString(_decodeMap(response), ['pdfUrl']);
  }

  Future<PagedResult<ReviewModel>> getReviews(
    String bookId, {
    String? accessToken,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _get(
      '/api/reviews/book/$bookId?page=$page&pageSize=$pageSize',
      token: accessToken,
    );
    return PagedResult<ReviewModel>.fromJson(
      _decodeMap(response),
      (item) => ReviewModel.fromJson(item),
    );
  }

  Future<void> createReview(
    String accessToken,
    String bookId,
    int rating,
    String comment,
  ) async {
    await _post(
      '/api/reviews',
      token: accessToken,
      body: {'bookId': bookId, 'rating': rating, 'comment': comment},
    );
  }

  Future<WishlistModel> getWishlist(String accessToken) async {
    final response = await _send(
      () => http.get(
        _uri('/api/wishlist'),
        headers: _headers(token: accessToken),
      ),
      allow404: true,
    );

    if (response.statusCode == 404) {
      return WishlistModel.empty();
    }

    return WishlistModel.fromJson(_decodeMap(response));
  }

  Future<void> addWishlist(String accessToken, String bookId) async {
    await _post('/api/wishlist', token: accessToken, body: {'bookId': bookId});
  }

  Future<void> removeWishlist(String accessToken, String bookId) async {
    await _delete('/api/wishlist/$bookId', token: accessToken);
  }

  Future<ShoppingCartModel> upsertCart({
    required String accessToken,
    required String cartId,
    required String userId,
    required List<CartItemInput> items,
    String? clientSecret,
    String? paymentIntentId,
  }) async {
    final response = await _post(
      '/api/cart',
      token: accessToken,
      body: {
        'id': cartId,
        'userId': userId,
        'clientSecret': clientSecret,
        'paymentIntentId': paymentIntentId,
        'items': items.map((item) => item.toJson()).toList(),
      },
    );

    return ShoppingCartModel.fromJson(_decodeMap(response));
  }

  Future<ShoppingCartModel> getCart(String accessToken, String cartId) async {
    final response = await _get('/api/cart/$cartId', token: accessToken);
    return ShoppingCartModel.fromJson(_decodeMap(response));
  }

  Future<void> deleteCart(String accessToken, String cartId) async {
    await _delete('/api/cart/$cartId', token: accessToken);
  }

  Future<ShoppingCartModel> createPaymentIntent(
    String accessToken,
    String cartId,
  ) async {
    final response = await _post('/api/payment/$cartId', token: accessToken);
    return ShoppingCartModel.fromJson(_decodeMap(response));
  }

  Future<OrderModel> createOrder(String accessToken, String cartId) async {
    final response = await _post(
      '/api/orders',
      token: accessToken,
      body: {'cartId': cartId},
    );
    return OrderModel.fromJson(_decodeMap(response));
  }

  Future<OrderModel> getOrder(String accessToken, String orderId) async {
    final response = await _get('/api/orders/$orderId', token: accessToken);
    return OrderModel.fromJson(_decodeMap(response));
  }

  Future<OrderModel> waitForPaidOrder(
    String accessToken,
    String orderId,
  ) async {
    var latest = await getOrder(accessToken, orderId);
    for (var i = 0; i < 10; i++) {
      if (latest.status == OrderStatus.paymentReceived) {
        return latest;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      latest = await getOrder(accessToken, orderId);
    }
    return latest;
  }

  Uri _uri(String path, {Map<String, String>? query}) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<http.Response> _get(String path, {String? token}) =>
      _send(() => http.get(_uri(path), headers: _headers(token: token)));

  Future<http.Response> _post(String path, {String? token, Object? body}) =>
      _send(
        () => http.post(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<void> _delete(String path, {String? token}) async {
    await _send(() => http.delete(_uri(path), headers: _headers(token: token)));
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool allow404 = false,
  }) async {
    try {
      final response = await request().timeout(_requestTimeout);
      if (allow404 && response.statusCode == 404) {
        return response;
      }
      _ensureSuccess(response);
      return response;
    } on SocketException {
      throw AppException(
        message:
            'Unable to reach LibroSphere API at $_baseUrl. Start Docker compose and make sure the emulator can access port 8080.',
      );
    } on TimeoutException {
      throw AppException(
        message:
            'LibroSphere API at $_baseUrl did not respond in time. Check that Docker is running on port 8080.',
      );
    }
  }

  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _decodeItems(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _decodeArray(
    Map<String, dynamic> json,
    String key,
  ) {
    final items = json[key];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed (${response.statusCode}).';
    String? code;
    Object? details;

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        details = decoded;

        if (decoded is Map<String, dynamic>) {
          code = readString(decoded, ['code', 'Code'], fallback: '');
          if (code.isEmpty) {
            code = null;
          }

          message = readString(decoded, [
            'error',
            'Error',
            'message',
            'Message',
            'title',
            'Title',
          ], fallback: message);

          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstEntry = errors.entries.first;
            final value = firstEntry.value;
            if (value is List && value.isNotEmpty) {
              message = value.first.toString();
            } else if (value != null) {
              message = value.toString();
            }
          }
        } else {
          message = decoded.toString();
        }
      } catch (_) {
        message = response.body;
      }
    }

    throw AppException(
      message: message,
      statusCode: response.statusCode,
      code: code,
      details: details,
    );
  }
}
