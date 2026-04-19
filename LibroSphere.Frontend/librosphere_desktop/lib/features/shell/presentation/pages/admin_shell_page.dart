import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../authors/presentation/pages/authors_page.dart';
import '../../../books/presentation/pages/books_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../../users/presentation/pages/users_page.dart';
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
  DashboardPage? _dashboardPage;
  UsersPage? _usersPage;
  BooksPage? _booksPage;
  AuthorsPage? _authorsPage;

  @override
  void initState() {
    super.initState();
    _token = widget.session.accessToken!;
    _ensurePageInitialized(0);
  }

  void _ensurePageInitialized(int index) {
    switch (index) {
      case 0:
        _dashboardPage ??= DashboardPage(
          viewModel: AppInjection.createDashboardViewModel(_token),
        );
        return;
      case 1:
        _usersPage ??= UsersPage(
          viewModel: AppInjection.createUsersViewModel(_token),
        );
        return;
      case 2:
        _booksPage ??= BooksPage(
          viewModel: AppInjection.createBooksViewModel(_token),
        );
        return;
      case 3:
        _authorsPage ??= AuthorsPage(
          viewModel: AppInjection.createAuthorsViewModel(_token),
        );
        return;
    }
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
                  ShellSideNav(
                    selectedTab: _tab,
                    onSelectTab: (tab) => setState(() {
                      _ensurePageInitialized(tab);
                      _tab = tab;
                    }),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        _dashboardPage ?? const SizedBox.shrink(),
                        _usersPage ?? const SizedBox.shrink(),
                        _booksPage ?? const SizedBox.shrink(),
                        _authorsPage ?? const SizedBox.shrink(),
                      ],
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
