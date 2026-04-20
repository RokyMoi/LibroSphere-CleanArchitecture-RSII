import 'package:flutter/material.dart';

import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';
import 'book_detail_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex = widget.initialTab;
  late final List<Widget?> _pages;
  final _homeKey = GlobalKey<MobileHomeScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);
    _pageAt(_currentIndex);
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
              MobileBottomNavigation(
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (index == 0) {
                    _homeKey.currentState?.refreshIfStale();
                  }

                  setState(() {
                    _pageAt(index);
                    _currentIndex = index;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageAt(int index) {
    final page = _pages[index];
    if (page != null) {
      return page;
    }

    final createdPage = switch (index) {
      0 => MobileHomeScreen(key: _homeKey, onOpenBook: _openBook),
      1 => LibraryScreen(onNavigateToTab: _navigateToTabFromOverlay),
      2 => const CartScreen(),
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
  }
}
