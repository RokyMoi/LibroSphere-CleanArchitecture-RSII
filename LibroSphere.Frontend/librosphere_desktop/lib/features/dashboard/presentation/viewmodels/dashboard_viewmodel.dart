import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository, this._token);

  final DashboardRepository _repository;
  final String _token;
  bool _hasLoaded = false;

  bool isLoading = true;
  Failure? failure;
  DashboardStatsModel? stats;

  Future<void> ensureLoaded() {
    if (_hasLoaded) {
      return Future<void>.value();
    }

    return load();
  }

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) {
      isLoading = true;
      notifyListeners();
    }

    failure = null;

    final result = await _repository.getDashboard(_token);

    switch (result) {
      case Success<DashboardStatsModel>(value: final dashboard):
        stats = dashboard;
        _hasLoaded = true;
      case ErrorResult<DashboardStatsModel>(failure: final error):
        failure = error is Failure
            ? error
            : Failure(message: error.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshIfLoaded() async {
    if (!_hasLoaded) {
      return;
    }

    final result = await _repository.getDashboard(_token);
    if (result case Success<DashboardStatsModel>(value: final dashboard)) {
      stats = dashboard;
      notifyListeners();
    }
  }
}
