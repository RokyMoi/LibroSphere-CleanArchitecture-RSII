import 'package:flutter/material.dart';

import '../core/app_constants.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.embedded = false,
    this.showNotifications = false,
    this.unreadCount = 0,
    this.onBellTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool embedded;
  final bool showNotifications;
  final int unreadCount;
  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      margin: EdgeInsets.fromLTRB(18, embedded ? 0 : 0, 18, 18),
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
          if (showNotifications)
            _NotificationBell(
              unreadCount: unreadCount,
              onTap: onBellTap,
            ),
          _NavIcon(
            icon: Icons.settings_outlined,
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );

    return embedded ? bar : SafeArea(top: false, child: bar);
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
