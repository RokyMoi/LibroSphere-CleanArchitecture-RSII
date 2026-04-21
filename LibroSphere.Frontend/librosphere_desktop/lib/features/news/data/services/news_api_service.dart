import '../../../../core/network/api_client.dart';
import '../models/admin_news_model.dart';

class NewsApiService {
  NewsApiService(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/news?take=N  — backend returns a direct JSON array
  Future<List<AdminNewsModel>> getNews(String token, {int take = 50}) async {
    final items = await _apiClient.getList(
      '/api/news',
      token: token,
      query: <String, String>{'take': take.toString()},
    );
    return items.map(AdminNewsModel.fromJson).toList();
  }

  Future<void> createNews({
    required String token,
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    await _apiClient.postJson(
      '/api/news',
      token: token,
      body: <String, dynamic>{
        'title': title,
        'text': text,
        'imageUrl': imageUrl,
      },
    );
  }

  Future<void> deleteNews({required String token, required String newsId}) {
    return _apiClient.delete('/api/news/$newsId', token: token);
  }

  /// Uploads an image file and returns the image URL
  Future<String> uploadNewsImage({
    required String token,
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    final response = await _apiClient.postMultipartJson(
      '/api/news/upload-image',
      token: token,
      files: [
        MultipartFileDescriptor(
          field: 'file',
          filename: filename,
          bytes: imageBytes,
          contentType: contentType,
        ),
      ],
    );
    return response['imageUrl'] as String? ?? '';
  }
}
