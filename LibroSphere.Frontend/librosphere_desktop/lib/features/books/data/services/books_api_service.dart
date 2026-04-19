import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/admin_author_model.dart';
import '../models/admin_book_model.dart';
import '../models/admin_genre_model.dart';
import '../models/book_assets_model.dart';
import '../models/books_data_model.dart';
import '../models/picked_file_payload.dart';

class BooksApiService {
  BooksApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminAuthorModel>> getAuthors(String token) async {
    final response = await _apiClient.getMap(
      '/api/author',
      token: token,
      query: <String, String>{
        'page': '1',
        'pageSize': '200',
      },
    );

    return readItems(response).map(AdminAuthorModel.fromJson).toList();
  }

  Future<List<AdminGenreModel>> getGenres(String token) async {
    final response = await _apiClient.getMap(
      '/api/genre',
      token: token,
      query: <String, String>{
        'page': '1',
        'pageSize': '200',
      },
    );

    return readItems(response).map(AdminGenreModel.fromJson).toList();
  }

  Future<BooksDataModel> getBooks(
    String token, {
    required int page,
    int pageSize = 12,
  }) async {
    final response = await _apiClient.getMap(
      '/api/book',
      token: token,
      query: <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    return BooksDataModel(
      authors: const <AdminAuthorModel>[],
      genres: const <AdminGenreModel>[],
      books: readItems(response).map(AdminBookModel.fromJson).toList(),
      page: readInt(response, <String>['page'], fallback: page),
      totalPages: readInt(response, <String>['totalPages'], fallback: 1),
      totalCount: readInt(response, <String>['totalCount']),
      hasPreviousPage: readBool(response, <String>['hasPreviousPage']),
      hasNextPage: readBool(response, <String>['hasNextPage']),
    );
  }

  Future<BookAssetsModel> getBookAssets(String token, String bookId) async {
    final response = await _apiClient.getMap(
      '/api/book/$bookId/assets',
      token: token,
    );

    return BookAssetsModel.fromJson(response);
  }

  Future<void> createBook({
    required String token,
    required String title,
    required String description,
    required double priceAmount,
    required String currencyCode,
    required String authorId,
    required List<String> genreIds,
    required PickedFilePayload imageFile,
    required PickedFilePayload pdfFile,
    UploadProgressCallback? onProgress,
  }) {
    return _apiClient.sendMultipart(
      method: 'POST',
      path: '/api/book',
      token: token,
      fields: <String, String>{
        'Title': title,
        'Description': description,
        'PriceAmount': priceAmount.toString(),
        'CurrencyCode': currencyCode,
        'AuthorId': authorId,
        ..._genreFields(genreIds),
      },
      files: <MultipartFileDescriptor>[
        MultipartFileDescriptor(
          field: 'ImageFile',
          filename: imageFile.name,
          bytes: imageFile.bytes,
          contentType: imageFile.contentType,
        ),
        MultipartFileDescriptor(
          field: 'PdfFile',
          filename: pdfFile.name,
          bytes: pdfFile.bytes,
          contentType: pdfFile.contentType,
        ),
      ],
      onProgress: onProgress,
    );
  }

  Future<void> updateBook({
    required String token,
    required String bookId,
    required String title,
    required String description,
    required double priceAmount,
    required String currencyCode,
    required String authorId,
    required List<String> genreIds,
    required String imageLink,
    required String pdfLink,
    PickedFilePayload? imageFile,
    PickedFilePayload? pdfFile,
    UploadProgressCallback? onProgress,
  }) {
    final files = <MultipartFileDescriptor>[
      if (imageFile != null)
        MultipartFileDescriptor(
          field: 'ImageFile',
          filename: imageFile.name,
          bytes: imageFile.bytes,
          contentType: imageFile.contentType,
        ),
      if (pdfFile != null)
        MultipartFileDescriptor(
          field: 'PdfFile',
          filename: pdfFile.name,
          bytes: pdfFile.bytes,
          contentType: pdfFile.contentType,
        ),
    ];

    return _apiClient.sendMultipart(
      method: 'PUT',
      path: '/api/book/$bookId',
      token: token,
      fields: <String, String>{
        'Title': title,
        'Description': description,
        'PriceAmount': priceAmount.toString(),
        'CurrencyCode': currencyCode,
        'AuthorId': authorId,
        ..._genreFields(genreIds),
        'ImageLink': imageLink,
        'PdfLink': pdfLink,
      },
      files: files,
      onProgress: onProgress,
    );
  }

  Future<void> deleteBook({
    required String token,
    required String bookId,
  }) {
    return _apiClient.delete(
      '/api/book/$bookId',
      token: token,
    );
  }

  Map<String, String> _genreFields(List<String> genreIds) {
    final fields = <String, String>{};

    for (var index = 0; index < genreIds.length; index++) {
      fields['GenreIds[$index]'] = genreIds[index];
    }

    return fields;
  }
}
