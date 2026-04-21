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

  Future<void> _openEditor([AdminBookModel? book]) async {
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

    final message = book == null
        ? 'Book was added successfully.'
        : 'Book was updated successfully.';
    _showSnackBar(message, isError: false);
  }

  Future<void> _deleteBook(AdminBookModel book) async {
    final shouldDelete = await _confirmDeletion(
      title: 'Delete Book',
      message:
          'Are you sure you want to permanently delete "${book.title}"?',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final result = await widget.viewModel.deleteBook(book);
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        _showSnackBar(
          'Book "${book.title}" was deleted successfully.',
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
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hintText: 'Search books by title, author...',
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
                        columns: ['Author', 'Name of Book', 'Book Price', ''],
                      ),
                      Expanded(
                        child: viewModel.books.isEmpty
                            ? const AdminEmptyState('No books found.')
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                itemCount: viewModel.books.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final book = viewModel.books[index];
                                  return _BookRow(
                                    book: book,
                                    authorName: viewModel.authorName(
                                      book.authorId,
                                    ),
                                    isDeleting:
                                        viewModel.deletingBookId == book.id,
                                    onEdit: () => _openEditor(book),
                                    onDelete: () => _deleteBook(book),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _BooksFooter(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                totalCount: viewModel.totalCount,
                hasPreviousPage: viewModel.hasPreviousPage,
                hasNextPage: viewModel.hasNextPage,
                onPreviousPage: viewModel.loadPreviousPage,
                onNextPage: viewModel.loadNextPage,
                onAddBook: () => _openEditor(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.authorName,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminBookModel book;
  final String authorName;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(authorName, style: _rowTextStyle),
        ),
        Expanded(
          child: Text(book.title, style: _rowTextStyle),
        ),
        Expanded(
          child: Text(
            formatCurrency(book.amount, book.currency),
            style: _rowTextStyle,
          ),
        ),
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

class _BooksFooter extends StatelessWidget {
  const _BooksFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onAddBook,
  });

  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: hasPreviousPage ? onPreviousPage : null,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Text(
                '$currentPage/$totalPages',
                style: _rowTextStyle.copyWith(fontSize: 16),
              ),
              IconButton(
                onPressed: hasNextPage ? onNextPage : null,
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
              const SizedBox(width: 18),
              AppButton(
                label: 'Add New Book',
                onPressed: onAddBook,
                width: 172,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total books: $totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
