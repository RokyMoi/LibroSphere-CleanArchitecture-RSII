import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ShellSideNav extends StatelessWidget {
  const ShellSideNav({
    super.key,
    required this.selectedTab,
    required this.onSelectTab,
  });

  final int selectedTab;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: desktopPrimaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _navIcon(Icons.stars_outlined, 0),
          const SizedBox(height: 18),
          _navIcon(Icons.person_outline_rounded, 1),
          const SizedBox(height: 18),
          _navIcon(Icons.menu_book_outlined, 2),
          const SizedBox(height: 18),
          _navIcon(Icons.local_offer_outlined, 3),
          const SizedBox(height: 18),
          _navIcon(Icons.edit_note_rounded, 4),
          const SizedBox(height: 18),
          _navIcon(Icons.picture_as_pdf_outlined, 5),
          const SizedBox(height: 18),
          _navIcon(Icons.shopping_bag_outlined, 6),
          const SizedBox(height: 18),
          _navIcon(Icons.newspaper_rounded, 7),
          const SizedBox(height: 18),
          _navIcon(Icons.settings_outlined, 8),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int tab) {
    final isActive = selectedTab == tab;
    return IconButton(
      onPressed: () => onSelectTab(tab),
      icon: Icon(
        icon,
        color: isActive ? Colors.white : desktopMutedForeground,
        size: 34,
      ),
    );
  }
}
