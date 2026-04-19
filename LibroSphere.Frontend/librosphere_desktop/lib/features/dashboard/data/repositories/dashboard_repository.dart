import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_api_service.dart';

class DashboardRepository {
  DashboardRepository(this._apiService);

  final DashboardApiService _apiService;

  Future<Result<DashboardStatsModel>> getDashboard(String token) async {
    try {
      final dashboard = await _apiService.getDashboard(token);
      return Success<DashboardStatsModel>(dashboard);
    } on AppException catch (exception) {
      return ErrorResult<DashboardStatsModel>(
        Failure.fromException(exception),
      );
    } catch (exception) {
      return ErrorResult<DashboardStatsModel>(
        Failure(message: exception.toString()),
      );
    }
  }
}
