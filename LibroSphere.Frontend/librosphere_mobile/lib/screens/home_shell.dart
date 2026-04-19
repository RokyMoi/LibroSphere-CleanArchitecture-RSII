import 'package:flutter/material.dart';

import '../data/models/book_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      MobileHomeScreen(
        key: const PageStorageKey<String>('home-tab'),
        onOpenBook: _openBook,
      ),
      const LibraryScreen(),
      const CartScreen(),
      const WishlistScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
              MobileBottomNavigation(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index)),
            ],
          ),
        ),
      ),
    );
  }

  void _openBook(BookModel book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(bookId: book.id),
      ),
    );
  }
}
