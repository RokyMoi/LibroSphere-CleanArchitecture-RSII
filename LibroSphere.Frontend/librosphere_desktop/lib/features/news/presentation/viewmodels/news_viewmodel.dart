import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_news_model.dart';
import '../../data/repositories/news_repository.dart';

class NewsViewModel extends ChangeNotifier {
  NewsViewModel(this._repository, this._token);

  final NewsRepository _repository;
  final String _token;
  bool _hasLoaded = false;

  bool isLoading = true;
  bool isSaving = false;
  String? deletingNewsId;
  Failure? failure;
  List<AdminNewsModel> newsList = <AdminNewsModel>[];

  Future<void> ensureLoaded() {
    if (_hasLoaded) return Future.value();
    return load();
  }

  Future<void> load() async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final result = await _repository.getNews(_token, take: 50);

    switch (result) {
      case Success<List<AdminNewsModel>>(value: final items):
        newsList = items;
        _hasLoaded = true;
      case ErrorResult<List<AdminNewsModel>>(failure: final error):
        failure = error is Failure ? error : Failure(message: error.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Result<void>> createNews({
    required String title,
    required String text,
    required String imageUrl,
  }) async {
    isSaving = true;
    notifyListeners();

    final result = await _repository.createNews(
      token: _token,
      title: title,
      text: text,
      imageUrl: imageUrl,
    );

    if (result is Success<void>) {
      await load();
    } else {
      isSaving = false;
      notifyListeners();
    }

    isSaving = false;
    notifyListeners();
    return result;
  }

  Future<Result<void>> deleteNews(AdminNewsModel news) async {
    deletingNewsId = news.id;
    notifyListeners();

    final result = await _repository.deleteNews(
      token: _token,
      newsId: news.id,
    );

    deletingNewsId = null;

    if (result is Success<void>) {
      await load();
    } else {
      notifyListeners();
    }

    return result;
  }

  Future<Result<String>> uploadNewsImage({
    required List<int> imageBytes,
    required String filename,
    required String contentType,
  }) async {
    return await _repository.uploadNewsImage(
      token: _token,
      imageBytes: imageBytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
