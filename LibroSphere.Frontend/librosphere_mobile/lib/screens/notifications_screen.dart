import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../data/models/notification_model.dart';
import '../features/session/presentation/viewmodels/notification_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.viewModel});

  final NotificationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final notifications = viewModel.notifications;
            return RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                itemCount: notifications.isEmpty ? 3 : notifications.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: brandBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              color: brandBlueDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (viewModel.hasUnread)
                          TextButton(
                            onPressed: viewModel.markAllRead,
                            child: const Text(
                              'Mark all read',
                              style: TextStyle(
                                color: brandBlueDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  if (index == 1) {
                    return const SizedBox(height: 18);
                  }
                  if (viewModel.loading && notifications.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (notifications.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: brandBlueDark,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No notifications yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final notification = notifications[index - 2];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () => viewModel.markRead(notification.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return InkWell(
      onTap: isRead ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFFF8FAFF) : const Color(0xFFEBF2FF),
          borderRadius: BorderRadius.circular(16),
          border: isRead
              ? null
              : Border.all(color: brandBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : brandBlue,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.occurredOnUtc),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.day}/${local.month}/${local.year}';
  }
}
