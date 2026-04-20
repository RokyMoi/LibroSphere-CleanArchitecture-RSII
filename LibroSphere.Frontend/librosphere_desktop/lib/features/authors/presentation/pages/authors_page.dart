import 'package:flutter/material.dart';

import '../../../../core/error/result.dart';
import '../../../../shared/widgets/admin/admin_empty_state.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/admin/table_header.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../viewmodels/authors_viewmodel.dart';
import '../widgets/add_edit_author_dialog.dart';

class AuthorsPage extends StatefulWidget {
  const AuthorsPage({super.key, required this.viewModel});

  final AuthorsViewModel viewModel;

  @override
  State<AuthorsPage> createState() => _AuthorsPageState();
}

class _AuthorsPageState extends State<AuthorsPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  Future<void> _openEditor([AdminAuthorModel? author]) async {
    final wasSaved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditAuthorDialog(
        viewModel: widget.viewModel,
        author: author,
      ),
    );

    if (!mounted || wasSaved != true) {
      return;
    }

    final message = author == null
        ? 'Author was added successfully.'
        : 'Author was updated successfully.';
    _showSnackBar(message, isError: false);
  }

  Future<void> _deleteAuthor(AdminAuthorModel author) async {
    final shouldDelete = await _confirmDeletion(
      title: 'Delete Author',
      message:
          'Are you sure you want to permanently delete "${author.name}"?\n\nThis will also delete all books by this author.',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final result = await widget.viewModel.deleteAuthor(author);
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        _showSnackBar(
          'Author "${author.name}" and all related books were deleted.',
          isError: false,
        );
      case ErrorResult<void>(failure: final error):
        _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<bool> _confirmDeletion({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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

    return result == true;
  }

  void _showSnackBar(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF1F8B4C),
        ),
      );
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
              Expanded(
                child: AdminPanel(
                  child: Column(
                    children: [
                      const TableHeader(
                        columns: ['Author', 'Biography', 'Action'],
                      ),
                      Expanded(
                        child: viewModel.authors.isEmpty
                            ? const AdminEmptyState('No authors found.')
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                itemCount: viewModel.authors.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final author = viewModel.authors[index];
                                  return _AuthorRow(
                                    author: author,
                                    isDeleting:
                                        viewModel.deletingAuthorId == author.id,
                                    onEdit: () => _openEditor(author),
                                    onDelete: () => _deleteAuthor(author),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _AuthorsFooter(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                totalCount: viewModel.totalCount,
                hasPreviousPage: viewModel.hasPreviousPage,
                hasNextPage: viewModel.hasNextPage,
                onPreviousPage: viewModel.loadPreviousPage,
                onNextPage: viewModel.loadNextPage,
                onAddAuthor: () => _openEditor(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminAuthorModel author;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            author.name,
            style: _rowTextStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            author.biography,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _secondaryRowTextStyle,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 236,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'EDIT',
                  onPressed: onEdit,
                  height: 38,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'DELETE',
                  onPressed: isDeleting ? null : onDelete,
                  height: 38,
                  isLoading: isDeleting,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorsFooter extends StatelessWidget {
  const _AuthorsFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onAddAuthor,
  });

  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onAddAuthor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: hasPreviousPage ? onPreviousPage : null,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Text(
              '$currentPage/$totalPages',
              style: _footerTextStyle,
            ),
            IconButton(
              onPressed: hasNextPage ? onNextPage : null,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Total authors: $totalCount',
              style: _footerCountTextStyle,
            ),
          ],
        ),
        AppButton(
          label: 'Add Author',
          onPressed: onAddAuthor,
          width: 160,
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

const TextStyle _secondaryRowTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

const TextStyle _footerTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

const TextStyle _footerCountTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);
