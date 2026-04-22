import '../../../../core/network/api_client.dart';
import '../models/admin_note_model.dart';

class AdminNotesApiService {
  AdminNotesApiService(this._apiClient);

  final ApiClient _apiClient;
  static const String _path = '/api/adminnotes';

  /// GET /api/adminnotes?take=N — backend returns a direct JSON array.
  Future<List<AdminNoteModel>> getAdminNotes(
    String token, {
    int take = 50,
  }) async {
    final items = await _apiClient.getList(
      _path,
      token: token,
      query: <String, String>{'take': take.toString()},
    );

    return items.map(AdminNoteModel.fromJson).toList();
  }

  Future<void> createAdminNote({
    required String token,
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    await _apiClient.postJson(
      _path,
      token: token,
      body: <String, dynamic>{
        'title': title,
        'text': text,
        'imageUrl': imageUrl,
      },
    );
  }

  Future<void> deleteAdminNote({
    required String token,
    required String adminNoteId,
  }) {
    return _apiClient.delete('$_path/$adminNoteId', token: token);
  }

  Future<String> uploadAdminNoteImage({
    required String token,
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    final response = await _apiClient.postMultipartJson(
      '$_path/upload-image',
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
