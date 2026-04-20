import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../authors/presentation/pages/authors_page.dart';
import '../../../authors/presentation/viewmodels/authors_viewmodel.dart';
import '../../../books/presentation/pages/books_page.dart';
import '../../../books/presentation/viewmodels/books_viewmodel.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../../genres/presentation/pages/genres_page.dart';
import '../../../genres/presentation/viewmodels/genres_viewmodel.dart';
import '../../../session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../../users/presentation/pages/users_page.dart';
import '../../../users/presentation/viewmodels/users_viewmodel.dart';
import '../widgets/shell_side_nav.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.session});

  final AdminSessionViewModel session;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _tab = 0;
  late final String _token;
  late final DashboardViewModel _dashboardViewModel;
  late final UsersViewModel _usersViewModel;
  late final BooksViewModel _booksViewModel;
  late final GenresViewModel _genresViewModel;
  late final AuthorsViewModel _authorsViewModel;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _token = widget.session.accessToken!;
    _dashboardViewModel = AppInjection.createDashboardViewModel(_token);
    _usersViewModel = AppInjection.createUsersViewModel(_token);
    _booksViewModel = AppInjection.createBooksViewModel(
      _token,
      onDataChanged: _dashboardViewModel.refreshIfLoaded,
    );
    _genresViewModel = AppInjection.createGenresViewModel(
      _token,
      onDataChanged: _handleGenresChanged,
    );
    _authorsViewModel = AppInjection.createAuthorsViewModel(
      _token,
      onDataChanged: _handleAuthorsChanged,
    );
    _pages = List<Widget?>.filled(5, null);
    _pageAt(0);
  }

  @override
  void dispose() {
    _dashboardViewModel.dispose();
    _usersViewModel.dispose();
    _booksViewModel.dispose();
    _genresViewModel.dispose();
    _authorsViewModel.dispose();
    super.dispose();
  }

  Future<void> _handleAuthorsChanged() async {
    await _dashboardViewModel.refreshIfLoaded();
    await _booksViewModel.refreshLookupData();
  }

  Future<void> _handleGenresChanged() async {
    await _dashboardViewModel.refreshIfLoaded();
    await _booksViewModel.refreshLookupData();
  }

  Widget _pageAt(int index) {
    final page = _pages[index];
    if (page != null) {
      return page;
    }

    final createdPage = switch (index) {
      0 => DashboardPage(viewModel: _dashboardViewModel),
      1 => UsersPage(viewModel: _usersViewModel),
      2 => BooksPage(viewModel: _booksViewModel),
      3 => GenresPage(viewModel: _genresViewModel),
      4 => AuthorsPage(viewModel: _authorsViewModel),
      _ => const SizedBox.shrink(),
    };

    _pages[index] = createdPage;
    return createdPage;
  }

  void _selectTab(int tab) {
    setState(() {
      _pageAt(tab);
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: desktopPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  ShellSideNav(selectedTab: _tab, onSelectTab: _selectTab),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: List<Widget>.generate(
                        _pages.length,
                        (index) => _pages[index] ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: widget.session.logout,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
