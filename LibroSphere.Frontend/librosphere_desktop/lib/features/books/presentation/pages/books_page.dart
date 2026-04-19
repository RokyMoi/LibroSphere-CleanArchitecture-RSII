import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/table_header.dart';
import '../../data/models/admin_book_model.dart';
import '../viewmodels/books_viewmodel.dart';
import '../widgets/add_edit_book_dialog.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, required this.viewModel});

  final BooksViewModel viewModel;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
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

  Future<void> _openEditor(AdminBookModel? book) async {
    await widget.viewModel.load(page: widget.viewModel.currentPage);

    if (!mounted) {
      return;
    }

    final wasSaved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditBookDialog(
        viewModel: widget.viewModel,
        book: book,
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
          book == null
              ? 'Book was added successfully.'
              : 'Book was updated successfully.',
        ),
        backgroundColor: const Color(0xFF1F8B4C),
      ),
    );
  }

  Future<void> _deleteBook(AdminBookModel book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: Text(
            'Are you sure you want to permanently delete "${book.title}"?',
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

    final result = await widget.viewModel.deleteBook(book);
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (result is Success<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Book "${book.title}" was deleted successfully.'),
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
                        columns: ['Author', 'Name of Book', 'Book Price', ''],
                      ),
                      if (widget.viewModel.books.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No books found.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        ...widget.viewModel.books.map(
                              (book) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.viewModel.authorName(
                                          book.authorId,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        book.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        formatCurrency(
                                          book.amount,
                                          book.currency,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 236,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AppButton(
                                              label: 'EDIT',
                                              onPressed: () => _openEditor(book),
                                              height: 38,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: AppButton(
                                              label: 'DELETE',
                                              onPressed: widget
                                                          .viewModel
                                                          .deletingBookId ==
                                                      book.id
                                                  ? null
                                                  : () => _deleteBook(book),
                                              height: 38,
                                              isLoading: widget
                                                      .viewModel
                                                      .deletingBookId ==
                                                  book.id,
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
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                    const SizedBox(width: 18),
                    AppButton(
                      label: 'Add New Book',
                      onPressed: () => _openEditor(null),
                      width: 172,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total books: ${widget.viewModel.totalCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
