import '../../../../core/network/api_client.dart';
import '../models/dashboard_stats_model.dart';

class DashboardApiService {
  DashboardApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardStatsModel> getDashboard(String token) async {
    final response = await _apiClient.getMap(
      '/api/analytics/overview',
      token: token,
    );

    return DashboardStatsModel.fromJson(response);
  }
}
