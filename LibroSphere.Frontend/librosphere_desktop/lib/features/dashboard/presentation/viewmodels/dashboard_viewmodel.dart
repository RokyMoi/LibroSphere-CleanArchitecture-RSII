import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository, this._token);

  final DashboardRepository _repository;
  final String _token;

  bool isLoading = true;
  Failure? failure;
  DashboardStatsModel? stats;

  Future<void> load() async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final result = await _repository.getDashboard(_token);

    switch (result) {
      case Success<DashboardStatsModel>(value: final dashboard):
        stats = dashboard;
      case ErrorResult<DashboardStatsModel>(failure: final error):
        failure = error is Failure
            ? error
            : Failure(message: error.toString());
    }

    isLoading = false;
    notifyListeners();
  }
}
