import 'package:flutter/material.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/admin/admin_empty_state.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/admin/table_header.dart';
import '../../data/models/admin_user_model.dart';
import '../viewmodels/users_viewmodel.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.viewModel});

  final UsersViewModel viewModel;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  Future<void> _deleteUser(AdminUserModel user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to permanently delete "${user.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final result = await widget.viewModel.deleteUser(user.id);
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    switch (result) {
      case Success<void>():
        messenger.showSnackBar(
          SnackBar(
            content: Text('User "${user.name}" was deleted.'),
            backgroundColor: Color(0xFF1F8B4C),
          ),
        );
      case ErrorResult<void>(failure: final error):
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: const Color(0xFFB42318),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;

        if (viewModel.isLoading) {
          return const LoadingView();
        }

        if (viewModel.failure != null) {
          return ErrorView(
            message: viewModel.failure!.message,
            onRetry: () => viewModel.load(),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hintText: 'Search users by name or email...',
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) => viewModel.search(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Search',
                    onPressed: () => viewModel.search(_searchController.text),
                    width: 100,
                  ),
                  if (viewModel.searchTerm.isNotEmpty) ...[  
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Clear',
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearSearch();
                      },
                      width: 80,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AdminPanel(
                  child: Column(
                    children: [
                      const TableHeader(
                        columns: [
                          'Ime Prezime',
                          'DatumReg',
                          'Last Login',
                          'Status',
                          'Action',
                        ],
                      ),
                      Expanded(
                        child: viewModel.users.isEmpty
                            ? const AdminEmptyState('No users found.')
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                itemCount: viewModel.users.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final user = viewModel.users[index];
                                  return _UserRow(
                                    user: user,
                                    isDeleting:
                                        viewModel.deletingUserId == user.id,
                                    onDelete: () => _deleteUser(user),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _UsersFooter(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                totalCount: viewModel.totalCount,
                hasPreviousPage: viewModel.hasPreviousPage,
                hasNextPage: viewModel.hasNextPage,
                onPreviousPage: viewModel.loadPreviousPage,
                onNextPage: viewModel.loadNextPage,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isDeleting,
    required this.onDelete,
  });

  final AdminUserModel user;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(user.name, style: _rowTextStyle)),
        Expanded(
          child: Text(
            formatAdminDate(user.dateRegistered),
            style: _rowTextStyle,
          ),
        ),
        Expanded(
          child: Text(
            formatAdminDateTime(user.lastLogin),
            style: _rowTextStyle,
          ),
        ),
        Expanded(
          child: Text(
            user.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: user.isActive
                  ? const Color(0xFFD7FFE7)
                  : const Color(0xFFFFE2E2),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: isDeleting ? 'Deleting...' : 'Delete',
              onPressed: isDeleting ? null : onDelete,
              width: 112,
              height: 38,
            ),
          ),
        ),
      ],
    );
  }
}

class _UsersFooter extends StatelessWidget {
  const _UsersFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: hasPreviousPage ? onPreviousPage : null,
              icon: const Icon(Icons.arrow_back, size: 32),
              color: Colors.white,
              disabledColor: Colors.white54,
            ),
            const SizedBox(width: 20),
            Text(currentPage.toString(), style: _rowTextStyle),
            const SizedBox(width: 16),
            const Text(
              '/',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            Text(totalPages.toString(), style: _rowTextStyle),
            const SizedBox(width: 20),
            IconButton(
              onPressed: hasNextPage ? onNextPage : null,
              icon: const Icon(Icons.arrow_forward, size: 32),
              color: Colors.white,
              disabledColor: Colors.white54,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total users: $totalCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

const TextStyle _rowTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);
