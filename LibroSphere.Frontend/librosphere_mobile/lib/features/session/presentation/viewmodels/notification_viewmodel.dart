import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/notification_model.dart';
import '../../../../services/app_services.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._services);

  static const _pollInterval = Duration(seconds: 20);

  final AppServices _services;

  List<NotificationModel> _notifications = const [];
  bool _loading = false;
  bool _isAppInForeground = true;
  bool _isDisposed = false;
  Timer? _pollTimer;
  String? _accessToken;

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  void startPolling(String accessToken) {
    if (_accessToken == accessToken && _pollTimer != null) return;
    _accessToken = accessToken;
    _restartPolling();
  }

  void setAppInForeground(bool isInForeground) {
    if (_isAppInForeground == isInForeground) {
      return;
    }

    _isAppInForeground = isInForeground;
    _restartPolling();
  }

  void stopPolling() {
    if (_isDisposed) {
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = null;
    _accessToken = null;
    _notifications = const [];
    _notifySafely();
  }

  Future<void> refresh() => _fetch();

  void _restartPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_accessToken == null || !_isAppInForeground) {
      return;
    }

    unawaited(_fetch());
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_fetch()));
  }

  Future<void> markRead(String notificationId) async {
    if (_isDisposed) {
      return;
    }
    final token = _accessToken;
    if (token == null) return;
    try {
      await _services.notifications.markRead(token, notificationId);
      if (_isDisposed) {
        return;
      }
      _notifications = _notifications.map((n) {
        return n.id == notificationId
            ? NotificationModel(
                id: n.id,
                isRead: true,
                title: n.title,
                text: n.text,
                occurredOnUtc: n.occurredOnUtc,
              )
            : n;
      }).toList();
      _notifySafely();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (_isDisposed) {
      return;
    }
    final token = _accessToken;
    if (token == null) return;
    try {
      await _services.notifications.markAllRead(token);
      if (_isDisposed) {
        return;
      }
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          isRead: true,
          title: n.title,
          text: n.text,
          occurredOnUtc: n.occurredOnUtc,
        );
      }).toList();
      _notifySafely();
    } catch (_) {}
  }

  Future<void> _fetch() async {
    if (_isDisposed) {
      return;
    }
    final token = _accessToken;
    if (token == null || _loading) return;
    try {
      final shouldShowLoadingState = _notifications.isEmpty;
      _loading = true;
      if (shouldShowLoadingState) {
        _notifySafely();
      }
      final items = await _services.notifications.getNotifications(token);
      if (_isDisposed) {
        return;
      }
      _notifications = items;
    } catch (_) {
      // Silently ignore polling failures
    } finally {
      _loading = false;
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
