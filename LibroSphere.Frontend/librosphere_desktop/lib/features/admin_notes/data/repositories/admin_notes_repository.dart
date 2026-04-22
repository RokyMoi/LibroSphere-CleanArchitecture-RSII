import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/admin_note_model.dart';
import '../services/admin_notes_api_service.dart';

class AdminNotesRepository {
  AdminNotesRepository(this._apiService);

  final AdminNotesApiService _apiService;

  Future<Result<List<AdminNoteModel>>> getAdminNotes(
    String token, {
    int take = 50,
  }) async {
    try {
      final adminNotes = await _apiService.getAdminNotes(token, take: take);
      return Success<List<AdminNoteModel>>(adminNotes);
    } on AppException catch (e) {
      return ErrorResult<List<AdminNoteModel>>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<List<AdminNoteModel>>(Failure(message: e.toString()));
    }
  }

  Future<Result<void>> createAdminNote({
    required String token,
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    if (title.trim().isEmpty) {
      return const ErrorResult<void>(Failure(message: 'Title is required.'));
    }
    if (text.trim().isEmpty) {
      return const ErrorResult<void>(Failure(message: 'Content is required.'));
    }

    try {
      await _apiService.createAdminNote(
        token: token,
        title: title.trim(),
        text: text.trim(),
        imageUrl: imageUrl.trim(),
      );
      return const Success<void>(null);
    } on AppException catch (e) {
      return ErrorResult<void>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<void>(Failure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteAdminNote({
    required String token,
    required String adminNoteId,
  }) async {
    try {
      await _apiService.deleteAdminNote(token: token, adminNoteId: adminNoteId);
      return const Success<void>(null);
    } on AppException catch (e) {
      return ErrorResult<void>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<void>(Failure(message: e.toString()));
    }
  }

  Future<Result<String>> uploadAdminNoteImage({
    required String token,
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final imageUrl = await _apiService.uploadAdminNoteImage(
        token: token,
        imageBytes: imageBytes,
        filename: filename,
        contentType: contentType,
      );
      return Success<String>(imageUrl);
    } on AppException catch (e) {
      return ErrorResult<String>(Failure.fromException(e));
    } catch (e) {
      return ErrorResult<String>(Failure(message: e.toString()));
    }
  }
}
