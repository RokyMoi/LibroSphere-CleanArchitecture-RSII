import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/table_header.dart';
import '../../../../core/error/result.dart';
import '../viewmodels/users_viewmodel.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.viewModel});

  final UsersViewModel viewModel;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to permanently delete "$userName"?',
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

    final result = await widget.viewModel.deleteUser(userId);
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (result is Success<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('User "$userName" was deleted.'),
          backgroundColor: const Color(0xFF1F8B4C),
        ),
      );
    } else if (result is ErrorResult<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.failure.toString()),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const LoadingView();
        }

        if (widget.viewModel.failure != null) {
          return ErrorView(
            message: widget.viewModel.failure!.message,
            onRetry: () => widget.viewModel.load(),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: desktopPrimaryLight.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TableHeader(
                        columns: const <String>[
                          'Ime Prezime',
                          'DatumReg',
                          'Last Login',
                          'Status',
                          'Action',
                        ],
                      ),
                      if (widget.viewModel.users.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No users found.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        ...widget.viewModel.users.map(
                              (user) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatAdminDate(user.dateRegistered),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatAdminDateTime(user.lastLogin),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                          label: widget.viewModel.deletingUserId == user.id
                                              ? 'Deleting...'
                                              : 'Delete',
                                          onPressed: widget.viewModel.deletingUserId == user.id
                                              ? null
                                              : () => _deleteUser(
                                                  user.id,
                                                  user.name,
                                                ),
                                          width: 112,
                                          height: 38,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: widget.viewModel.hasPreviousPage
                        ? () => widget.viewModel.loadPreviousPage()
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 32),
                    color: Colors.white,
                    disabledColor: Colors.white54,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    widget.viewModel.currentPage.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  Text(
                    widget.viewModel.totalPages.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: widget.viewModel.hasNextPage
                        ? () => widget.viewModel.loadNextPage()
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 32),
                    color: Colors.white,
                    disabledColor: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total users: ${widget.viewModel.totalCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
