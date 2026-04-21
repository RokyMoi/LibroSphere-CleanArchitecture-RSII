import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../data/models/book_model.dart';
import '../data/models/notification_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../features/session/presentation/viewmodels/notification_viewmodel.dart';
import '../screens/book_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/wishlist_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late int _currentIndex = widget.initialTab;
  late final List<Widget?> _pages;
  final _homeKey = GlobalKey<MobileHomeScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _cartKey = GlobalKey<CartScreenState>();
  late final NotificationViewModel _notifications;
  Timer? _notificationStartTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = List<Widget?>.filled(5, null);
    _pageAt(_currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.read(context);

    // Lazy-init notification viewmodel on first access to services
    if (!_notificationsInitialized) {
      _notifications = NotificationViewModel(session.services);
      _notificationsInitialized = true;
    }

    if (session.isAuthenticated && session.accessToken != null) {
      _notifications.setAppInForeground(
        WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      _scheduleNotificationStart(session.accessToken!);
    } else {
      _notificationStartTimer?.cancel();
      _notifications.stopPolling();
    }
  }

  bool _notificationsInitialized = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationStartTimer?.cancel();
    _notifications.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_notificationsInitialized) {
      return;
    }

    final isForeground = state == AppLifecycleState.resumed;
    _notifications.setAppInForeground(isForeground);
    if (!isForeground) {
      _notificationStartTimer?.cancel();
    }
  }

  void _scheduleNotificationStart(String accessToken) {
    _notificationStartTimer?.cancel();
    _notificationStartTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }

      _notifications.startPolling(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: List<Widget>.generate(
                    _pages.length,
                    (index) => _pages[index] ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: _notificationsInitialized
                    ? _notifications
                    : ChangeNotifier(),
                builder: (context, _) => _BottomNavWithBell(
                  currentIndex: _currentIndex,
                  unreadCount: _notificationsInitialized
                      ? _notifications.unreadCount
                      : 0,
                  onTap: (index) {
                    setState(() {
                      _pageAt(index);
                      _currentIndex = index;
                    });
                    _refreshTab(index);
                  },
                  onBellTap: _openNotifications,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageAt(int index) {
    final page = _pages[index];
    if (page != null) return page;

    final createdPage = switch (index) {
      0 => MobileHomeScreen(key: _homeKey, onOpenBook: _openBook),
      1 => LibraryScreen(
          key: _libraryKey,
          onNavigateToTab: _navigateToTabFromOverlay,
        ),
      2 => CartScreen(key: _cartKey),
      3 => const WishlistScreen(),
      4 => const SettingsScreen(),
      _ => const SizedBox.shrink(),
    };

    _pages[index] = createdPage;
    return createdPage;
  }

  void _openBook(BookModel book) {
    final session = SessionScope.read(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          bookId: book.id,
          session: session,
          onNavigateToTab: _navigateToTabFromOverlay,
        ),
      ),
    );
  }

  void _navigateToTabFromOverlay(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _pageAt(index);
      _currentIndex = index;
    });
    _refreshTab(index);
  }

  void _refreshTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (index == 0) {
        _homeKey.currentState?.refreshIfStale();
      } else if (index == 1) {
        _libraryKey.currentState?.refresh();
      } else if (index == 2) {
        _cartKey.currentState?.refresh();
      }
    });
  }

  void _openNotifications() {
    if (!_notificationsInitialized) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(viewModel: _notifications),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav with notification bell
// ---------------------------------------------------------------------------
class _BottomNavWithBell extends StatelessWidget {
  const _BottomNavWithBell({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
    required this.onBellTap,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: brandBlue,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.home_outlined,
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavIcon(
            icon: Icons.menu_book_outlined,
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavIcon(
            icon: Icons.shopping_cart_outlined,
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.bookmark_border_rounded,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          // Notification bell with badge
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: unreadCount > 0
                      ? Colors.white
                      : const Color(0xB4D3E6FF),
                  size: 31,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: active ? Colors.white : const Color(0xB4D3E6FF),
        size: 31,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications screen
// ---------------------------------------------------------------------------
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
                      fontWeight:
                          isRead ? FontWeight.w600 : FontWeight.w800,
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
