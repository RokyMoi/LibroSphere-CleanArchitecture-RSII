import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_note_model.dart';
import '../../data/repositories/admin_notes_repository.dart';

class AdminNotesViewModel extends ChangeNotifier {
  AdminNotesViewModel(this._repository, this._token);

  final AdminNotesRepository _repository;
  final String _token;
  bool _hasLoaded = false;
  bool _disposed = false;

  bool isLoading = true;
  bool isSaving = false;
  String? deletingAdminNoteId;
  Failure? failure;
  List<AdminNoteModel> adminNotes = <AdminNoteModel>[];

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> ensureLoaded() {
    if (_hasLoaded) return Future.value();
    return load();
  }

  Future<void> load() async {
    isLoading = true;
    failure = null;
    _safeNotify();

    final result = await _repository.getAdminNotes(_token, take: 50);

    switch (result) {
      case Success<List<AdminNoteModel>>(value: final items):
        adminNotes = items;
        _hasLoaded = true;
      case ErrorResult<List<AdminNoteModel>>(failure: final error):
        failure = error is Failure ? error : Failure(message: error.toString());
    }

    isLoading = false;
    _safeNotify();
  }

  Future<Result<void>> createAdminNote({
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    isSaving = true;
    _safeNotify();

    final result = await _repository.createAdminNote(
      token: _token,
      title: title,
      text: text,
      imageUrl: imageUrl,
    );

    isSaving = false;
    if (result is Success<void>) {
      await load();
    } else {
      _safeNotify();
    }

    return result;
  }

  Future<Result<void>> deleteAdminNote(AdminNoteModel adminNote) async {
    deletingAdminNoteId = adminNote.id;
    _safeNotify();

    final result = await _repository.deleteAdminNote(
      token: _token,
      adminNoteId: adminNote.id,
    );

    deletingAdminNoteId = null;

    if (result is Success<void>) {
      await load();
    } else {
      _safeNotify();
    }

    return result;
  }

  Future<Result<String>> uploadAdminNoteImage({
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    return await _repository.uploadAdminNoteImage(
      token: _token,
      imageBytes: imageBytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
