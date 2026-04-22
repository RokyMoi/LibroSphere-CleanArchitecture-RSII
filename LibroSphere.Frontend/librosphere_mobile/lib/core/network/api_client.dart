import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/author_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/cart_item_input.dart';
import '../../data/models/genre_model.dart';
import '../../data/models/home_feed_model.dart';
import '../../data/models/json_helpers.dart';
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
  ApiClient(this._client);

  static const _requestTimeout = Duration(seconds: 30);
  static const _maxGetRetries = 2;
  static const _largePayloadThreshold = 8 * 1024;

  final http.Client _client;
  final String _baseUrl = resolveApiBaseUrl();

  String _networkAccessHint() {
    if (kIsWeb) {
      return 'Open the API on http://localhost:8080 and verify Docker is running.';
    }

    if (Platform.isAndroid) {
      return 'Docker is probably fine. Android emulators must reach the host via http://10.0.2.2:8080. If needed, run `adb reverse tcp:8080 tcp:8080` or start Flutter with `--dart-define=LIBROSPHERE_API_URL=http://10.0.2.2:8080`.';
    }

    return 'Check that Docker is running and the API is reachable on port 8080.';
  }

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

  Future<void> requestPasswordReset(String email) async {
    await _post(
      '/api/auth/forgot-password',
      body: {'email': email},
    );
  }

  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post(
      '/api/auth/reset-password',
      body: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final response = await _get('/api/user/me', token: accessToken);
    return _decodeMap(response);
  }

  Future<void> updateProfile(
    String accessToken,
    String firstName,
    String lastName,
  ) async {
    await _put(
      '/api/user/me/profile',
      token: accessToken,
      body: {'firstName': firstName, 'lastName': lastName},
    );
  }

  Future<void> changePassword(
    String accessToken,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    await _post(
      '/api/user/me/change-password',
      token: accessToken,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getOrders(
    String accessToken, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _get(
      '/api/orders?page=$page&pageSize=$pageSize',
      token: accessToken,
    );
    final json = await _decodeMap(response);
    return _decodeItemsFromMap(json);
  }

  Future<void> refundOrder(String accessToken, String orderId) async {
    await _post(
      '/api/orders/$orderId/refund',
      token: accessToken,
      body: const <String, dynamic>{
        'reason': 'Requested by customer from mobile app',
      },
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications(
    String accessToken, {
    int take = 20,
  }) async {
    final response = await _get(
      '/api/notifications?take=$take',
      token: accessToken,
    );
    final body = await _decodeBody(response);
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<void> markNotificationRead(
    String accessToken,
    String notificationId,
  ) async {
    await _post(
      '/api/notifications/$notificationId/read',
      token: accessToken,
      body: const <String, dynamic>{},
    );
  }

  Future<void> markAllNotificationsRead(String accessToken) async {
    await _post(
      '/api/notifications/read-all',
      token: accessToken,
      body: const <String, dynamic>{},
    );
  }

  Future<String?> getStripePublishableKey() async {
    final response = await _get('/api/payment/config');
    final json = await _decodeMap(response);
    final value = readString(json, [
      'publishableKey',
      'PublishableKey',
    ]);
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<List<AuthorModel>> getAuthors() async {
    final response = await _get('/api/author?page=1&pageSize=200');
    final items = _decodeItemsFromMap(await _decodeMap(response));
    return items.map(AuthorModel.fromJson).toList();
  }

  Future<List<GenreModel>> getGenres() async {
    final response = await _get('/api/genre?page=1&pageSize=200');
    final items = _decodeItemsFromMap(await _decodeMap(response));
    return items.map(GenreModel.fromJson).toList();
  }

  Future<PagedResult<BookModel>> getBooks({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? authorId,
    String? genreId,
    double? minPrice,
    double? maxPrice,
    String? accessToken,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    if (authorId != null && authorId.isNotEmpty) {
      queryParams['authorId'] = authorId;
    }
    if (genreId != null && genreId.isNotEmpty) {
      queryParams['genreId'] = genreId;
    }
    if (minPrice != null) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice.toString();
    }

    final response = await _get(
      '/api/book?${_encodeQuery(queryParams)}',
      token: accessToken,
    );
    return PagedResult<BookModel>.fromJson(
      await _decodeMap(response),
      (item) => BookModel.fromJson(item),
    );
  }

  Future<HomeFeedModel> getHomeFeed({
    int page = 1,
    int pageSize = 8,
    int takeRecommendations = 4,
    String? searchTerm,
    String? accessToken,
  }) async {
    final response = await _get(
      '/api/book/home?${_encodeQuery({
        'page': '$page',
        'pageSize': '$pageSize',
        'takeRecommendations': '$takeRecommendations',
        if (searchTerm != null && searchTerm.trim().isNotEmpty)
          'searchTerm': searchTerm.trim(),
      })}',
      token: accessToken,
    );

    final json = await _decodeMap(response);
    final newest = PagedResult<BookModel>(
      items: _decodeArrayFromMap(json, 'newest').map(BookModel.fromJson).toList(),
      page: readInt(json, ['page', 'Page']),
      pageSize: readInt(json, ['pageSize', 'PageSize']),
      totalCount: readInt(json, ['totalCount', 'TotalCount']),
    );
    final recommendations = _decodeArrayFromMap(
      json,
      'recommendations',
    ).map(BookModel.fromJson).toList();

    return HomeFeedModel(newest: newest, recommendations: recommendations);
  }

  Future<BookModel> getBook(String bookId, String? accessToken) async {
    final response = await _get('/api/book/$bookId', token: accessToken);
    return BookModel.fromJson(await _decodeMap(response));
  }

  Future<List<BookModel>> getRecommendations(String accessToken) async {
    final response = await _get(
      '/api/recommendations?take=5',
      token: accessToken,
    );
    final decoded = await _decodeBody(response);
    if (decoded is! List) {
      return <BookModel>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromJson)
        .toList();
  }

  Future<PagedResult<LibraryEntry>> getLibrary(
    String accessToken, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _get(
      '/api/library?page=$page&pageSize=$pageSize',
      token: accessToken,
    );
    return PagedResult<LibraryEntry>.fromJson(
      await _decodeMap(response),
      (item) => LibraryEntry.fromJson(item),
    );
  }

  Future<String> getReadUrl(String accessToken, String bookId) async {
    final response = await _get(
      '/api/library/$bookId/read',
      token: accessToken,
    );
    return readString(await _decodeMap(response), ['pdfUrl']);
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
      await _decodeMap(response),
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
    final response = await _get(
      '/api/wishlist',
      token: accessToken,
      allow404: true,
    );

    if (response.statusCode == 404) {
      return WishlistModel.empty();
    }

    return WishlistModel.fromJson(await _decodeMap(response));
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

    return ShoppingCartModel.fromJson(await _decodeMap(response));
  }

  Future<ShoppingCartModel> getCart(String accessToken, String cartId) async {
    final response = await _get('/api/cart/$cartId', token: accessToken);
    return ShoppingCartModel.fromJson(await _decodeMap(response));
  }

  Future<void> deleteCart(String accessToken, String cartId) async {
    await _delete('/api/cart/$cartId', token: accessToken);
  }

  Future<ShoppingCartModel> createPaymentIntent(
    String accessToken,
    String cartId,
  ) async {
    final response = await _post('/api/payment/$cartId', token: accessToken);
    return ShoppingCartModel.fromJson(await _decodeMap(response));
  }

  Future<OrderModel> createOrder(String accessToken, String cartId) async {
    final response = await _post(
      '/api/orders',
      token: accessToken,
      body: {'cartId': cartId},
    );
    return OrderModel.fromJson(await _decodeMap(response));
  }

  Future<OrderModel> getOrder(String accessToken, String orderId) async {
    final response = await _get('/api/orders/$orderId', token: accessToken);
    return OrderModel.fromJson(await _decodeMap(response));
  }

  Future<OrderModel> waitForPaidOrder(
    String accessToken,
    String orderId, {
    int maxAttempts = 5,
  }) async {
    var latest = await getOrder(accessToken, orderId);
    var delay = const Duration(milliseconds: 600);

    for (var i = 0; i < maxAttempts; i++) {
      if (latest.status == OrderStatus.paymentReceived) {
        return latest;
      }

      await Future<void>.delayed(delay);
      delay = Duration(
        milliseconds: (delay.inMilliseconds * 1.5).round().clamp(600, 2500),
      );
      latest = await getOrder(accessToken, orderId);
    }
    return latest;
  }

  Future<String> uploadProfilePicture({
    required String accessToken,
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    final uri = _uri('/api/user/me/profile-picture');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: _parseMediaType(contentType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _ensureSuccess(response);

    final json = await _decodeMap(response);
    return readString(json, ['profilePictureUrl', 'ProfilePictureUrl']);
  }

  static http.MediaType _parseMediaType(String contentType) {
    final parts = contentType.split('/');
    if (parts.length == 2) {
      return http.MediaType(parts[0], parts[1]);
    }
    return http.MediaType('application', 'octet-stream');
  }

  Uri _uri(String path, {Map<String, String>? query}) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<http.Response> _get(
    String path, {
    String? token,
    bool allow404 = false,
  }) {
    return _send(
      () => _client.get(_uri(path), headers: _headers(token: token)),
      allow404: allow404,
      retries: _maxGetRetries,
    );
  }

  Future<http.Response> _post(String path, {String? token, Object? body}) =>
      _send(
        () => _client.post(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<http.Response> _put(String path, {String? token, Object? body}) =>
      _send(
        () => _client.put(
          _uri(path),
          headers: _headers(token: token),
          body: body == null ? null : jsonEncode(body),
        ),
      );

  Future<void> _delete(String path, {String? token}) async {
    await _send(() => _client.delete(_uri(path), headers: _headers(token: token)));
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool allow404 = false,
    int retries = 0,
  }) async {
    var attempt = 0;

    while (true) {
      try {
        final response = await request().timeout(_requestTimeout);
        if (allow404 && response.statusCode == 404) {
          return response;
        }
        _ensureSuccess(response);
        return response;
      } on SocketException {
        if (attempt >= retries) {
          throw AppException(
            message:
                'Unable to reach LibroSphere API at $_baseUrl. ${_networkAccessHint()}',
          );
        }
      } on TimeoutException {
        if (attempt >= retries) {
          throw AppException(
            message:
                'LibroSphere API at $_baseUrl did not respond in time. ${_networkAccessHint()}',
          );
        }
      }

      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
  }

  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _decodeMap(http.Response response) async {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = await _decodeBody(response);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<dynamic> _decodeBody(http.Response response) async {
    final bodyBytes = response.bodyBytes;
    if (bodyBytes.isEmpty) {
      return null;
    }

    if (bodyBytes.length < _largePayloadThreshold) {
      final body = utf8.decode(bodyBytes);
      return jsonDecode(body);
    }

    return compute(_decodeJsonBytesBody, bodyBytes);
  }

  List<Map<String, dynamic>> _decodeItemsFromMap(Map<String, dynamic> json) {
    final items = json['items'] ?? json['Items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _decodeArrayFromMap(
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
          final nestedError = readMap(decoded, ['error', 'Error']);
          final messageSource = nestedError.isNotEmpty ? nestedError : decoded;

          code = readNullableString(messageSource, [
            'code',
            'Code',
            'type',
            'Type',
          ]);

          message = readString(messageSource, [
            'message',
            'Message',
            'detail',
            'Detail',
            'title',
            'Title',
          ], fallback: message);

          if (message == 'Request failed (${response.statusCode}).') {
            message = readString(decoded, [
              'error',
              'Error',
              'message',
              'Message',
              'title',
              'Title',
            ], fallback: message);
          }

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

  String _encodeQuery(Map<String, String> queryParams) {
    return queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }
}

dynamic _decodeJsonBytesBody(List<int> bodyBytes) {
  return jsonDecode(utf8.decode(bodyBytes));
}
