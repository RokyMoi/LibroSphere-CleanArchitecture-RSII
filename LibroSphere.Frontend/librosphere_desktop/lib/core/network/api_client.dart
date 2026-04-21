import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../error/app_exception.dart';

typedef UploadProgressCallback = void Function(double progress);

class MultipartFileDescriptor {
  const MultipartFileDescriptor({
    required this.field,
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String field;
  final String filename;
  final List<int> bytes;
  final String contentType;
}

class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final UploadProgressCallback? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final callback = onProgress;
    if (callback == null) {
      return byteStream;
    }

    final totalBytes = contentLength;
    var sentBytes = 0;
    callback(0);

    final stream = byteStream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          sentBytes += chunk.length;
          if (totalBytes > 0) {
            callback((sentBytes / totalBytes).clamp(0, 1).toDouble());
          }
          sink.add(chunk);
        },
      ),
    );

    return http.ByteStream(stream);
  }
}

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String baseUrl;

  Uri _uri(String path, {Map<String, String>? query}) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> getMap(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => http.get(_uri(path, query: query), headers: _headers(token)),
    );

    return _decodeMap(response.body);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => http.get(_uri(path, query: query), headers: _headers(token)),
    );

    final decoded = _decodeDynamic(response.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'] ?? decoded['data'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Future<dynamic> postJson(
    String path, {
    String? token,
    Object? body,
  }) async {
    final response = await _send(
      () => http.post(
        _uri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    return _decodeDynamic(response.body);
  }

  Future<dynamic> putJson(
    String path, {
    String? token,
    Object? body,
  }) async {
    final response = await _send(
      () => http.put(
        _uri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );

    return _decodeDynamic(response.body);
  }

  Future<void> delete(
    String path, {
    String? token,
  }) async {
    await _send(
      () => http.delete(_uri(path), headers: _headers(token)),
    );
  }

  Future<void> sendMultipart({
    required String method,
    required String path,
    required String token,
    required Map<String, String> fields,
    List<MultipartFileDescriptor> files = const <MultipartFileDescriptor>[],
    UploadProgressCallback? onProgress,
  }) async {
    final request = _ProgressMultipartRequest(
      method,
      _uri(path),
      onProgress: onProgress,
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: MediaType.parse(file.contentType),
        ),
      );
    }

    try {
      final response = await request.send().timeout(
        ApiConstants.uploadRequestTimeout,
      );
      await _ensureStreamSuccess(response);
      onProgress?.call(1);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on TimeoutException catch (error) {
      throw _uploadTimeoutException(error);
    }
  }

  /// Multipart POST that returns JSON response
  Future<Map<String, dynamic>> postMultipartJson(
    String path, {
    required String token,
    List<MultipartFileDescriptor> files = const <MultipartFileDescriptor>[],
    Map<String, String> fields = const <String, String>{},
  }) async {
    final request = _ProgressMultipartRequest('POST', _uri(path))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: MediaType.parse(file.contentType),
        ),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(
        ApiConstants.uploadRequestTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);
      _ensureSuccess(response.statusCode, response.body);
      return _decodeMap(response.body);
    } on SocketException catch (error) {
      throw _networkException(error);
    } on TimeoutException catch (error) {
      throw _uploadTimeoutException(error);
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(ApiConstants.requestTimeout);
      _ensureSuccess(response.statusCode, response.body);
      return response;
    } on SocketException catch (error) {
      throw _networkException(error);
    } on TimeoutException catch (error) {
      throw _timeoutException(error);
    }
  }

  Future<void> _ensureStreamSuccess(http.StreamedResponse response) async {
    final body = await response.stream.bytesToString();
    _ensureSuccess(response.statusCode, body);
  }

  void _ensureSuccess(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    final decoded = _tryDecode(body);
    throw AppException(
      message: _extractMessage(statusCode, decoded, body),
      statusCode: statusCode,
      details: decoded ?? body,
    );
  }

  Map<String, String> _headers(String? token) => <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  dynamic _decodeDynamic(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(body);
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = _decodeDynamic(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Object? _tryDecode(String body) {
    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractMessage(int statusCode, Object? decoded, String rawBody) {
    if (decoded is Map<String, dynamic>) {
      final directMessage = _firstString(decoded, <String>[
        'error',
        'message',
        'title',
        'detail',
      ]);

      if (directMessage != null && directMessage.isNotEmpty) {
        return directMessage;
      }

      final errors = decoded['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }

          if (value != null) {
            return value.toString();
          }
        }
      }
    }

    if (rawBody.trim().isNotEmpty) {
      return rawBody;
    }

    return 'Request failed ($statusCode).';
  }

  String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  AppException _networkException(Object error) {
    return AppException(
      message: 'Unable to reach LibroSphere API at $baseUrl. '
          'Start Docker and use port 8080 only.',
      details: error,
    );
  }

  AppException _timeoutException(Object error) {
    return AppException(
      message: 'LibroSphere API at $baseUrl did not respond in time. '
          'Check that Docker is running on port 8080.',
      details: error,
    );
  }

  AppException _uploadTimeoutException(Object error) {
    return AppException(
      message: 'Book upload is taking too long. '
          'The API may still be processing the file, so wait a moment and refresh the books list.',
      details: error,
    );
  }
}
