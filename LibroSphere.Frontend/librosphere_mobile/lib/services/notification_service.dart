import '../core/network/api_client.dart';
import '../data/models/notification_model.dart';

class NotificationService {
  NotificationService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NotificationModel>> getNotifications(
    String accessToken, {
    int take = 20,
  }) async {
    final items = await _apiClient.getNotifications(accessToken, take: take);
    return items.map(NotificationModel.fromJson).toList();
  }

  Future<void> markRead(String accessToken, String notificationId) =>
      _apiClient.markNotificationRead(accessToken, notificationId);

  Future<void> markAllRead(String accessToken) =>
      _apiClient.markAllNotificationsRead(accessToken);
}
