import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/table_header.dart';
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
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  Future<void> _openEditor(AdminAuthorModel? author) async {
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

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          author == null
              ? 'Author was added successfully.'
              : 'Author was updated successfully.',
        ),
        backgroundColor: const Color(0xFF1F8B4C),
      ),
    );
  }

  Future<void> _deleteAuthor(AdminAuthorModel author) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Author'),
          content: Text(
            'Are you sure you want to permanently delete "${author.name}"?\n\nThis will also delete all books by this author.',
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

    final result = await widget.viewModel.deleteAuthor(author);
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (result is Success<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Author "${author.name}" and all related books were deleted.',
          ),
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
                        columns: const ['Author', 'Biography', 'Action'],
                      ),
                      if (widget.viewModel.authors.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No authors found.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        ...widget.viewModel.authors.map(
                              (author) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        author.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        author.biography,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                              onPressed: () => _openEditor(
                                                author,
                                              ),
                                              height: 38,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: AppButton(
                                              label: 'DELETE',
                                              onPressed: widget
                                                          .viewModel
                                                          .deletingAuthorId ==
                                                      author.id
                                                  ? null
                                                  : () => _deleteAuthor(author),
                                              height: 38,
                                              isLoading: widget
                                                      .viewModel
                                                      .deletingAuthorId ==
                                                  author.id,
                                            ),
                                          ),
                                        ],
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.viewModel.hasPreviousPage
                            ? () => widget.viewModel.loadPreviousPage()
                            : null,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        '${widget.viewModel.currentPage}/${widget.viewModel.totalPages}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.viewModel.hasNextPage
                            ? () => widget.viewModel.loadNextPage()
                            : null,
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Total authors: ${widget.viewModel.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    label: 'Add Author',
                    onPressed: () => _openEditor(null),
                    width: 160,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
