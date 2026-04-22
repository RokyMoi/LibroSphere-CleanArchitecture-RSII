import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../features/session/presentation/viewmodels/notification_viewmodel.dart';
import '../screens/book_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/wishlist_screen.dart';
import '../widgets/app_bottom_navigation.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late int _currentIndex = widget.initialTab;
  late final List<Widget?> _pages;
  late final Set<int> _initializedTabs;
  final _homeKey = GlobalKey<MobileHomeScreenState>();
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _cartKey = GlobalKey<CartScreenState>();
  final ValueNotifier<int> _notificationPlaceholder = ValueNotifier<int>(0);
  NotificationViewModel? _notifications;
  Timer? _notificationStartTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = List<Widget?>.filled(5, null);
    _pageAt(_currentIndex);
    _initializedTabs = <int>{_currentIndex};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.read(context);

    if (session.isAuthenticated && session.accessToken != null) {
      _notifications?.setAppInForeground(
        WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      _scheduleNotificationStart(session.accessToken!);
    } else {
      _notificationStartTimer?.cancel();
      _notifications?.stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationStartTimer?.cancel();
    _notifications?.stopPolling();
    _notifications?.dispose();
    _notificationPlaceholder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_notifications == null) {
      return;
    }

    final isForeground = state == AppLifecycleState.resumed;
    _notifications?.setAppInForeground(isForeground);
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

      final notifications = _ensureNotificationsInitialized();
      notifications.startPolling(accessToken);
    });
  }

  NotificationViewModel _ensureNotificationsInitialized() {
    final existing = _notifications;
    if (existing != null) {
      return existing;
    }

    final notifications =
        NotificationViewModel(SessionScope.read(context).services);
    _notifications = notifications;
    return notifications;
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
                listenable: _notifications ?? _notificationPlaceholder,
                builder: (context, _) => AppBottomNavigationBar(
                  currentIndex: _currentIndex,
                  showNotifications: true,
                  unreadCount: _notifications?.unreadCount ?? 0,
                  onTap: (index) {
                    final wasInitialized = _initializedTabs.contains(index);
                    setState(() {
                      _pageAt(index);
                      _initializedTabs.add(index);
                      _currentIndex = index;
                    });
                    if (wasInitialized) {
                      _refreshTab(index);
                    }
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
    final wasInitialized = _initializedTabs.contains(index);
    setState(() {
      _pageAt(index);
      _initializedTabs.add(index);
      _currentIndex = index;
    });
    if (wasInitialized) {
      _refreshTab(index);
    }
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
    final session = SessionScope.read(context);
    final notifications = _ensureNotificationsInitialized();
    final token = session.accessToken;
    if (session.isAuthenticated && token != null) {
      notifications.startPolling(token);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(viewModel: notifications),
      ),
    );
  }
}
