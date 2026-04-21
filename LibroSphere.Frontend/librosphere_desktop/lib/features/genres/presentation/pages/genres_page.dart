import 'package:flutter/material.dart';

import '../../../../core/error/result.dart';
import '../../../../shared/widgets/admin/admin_empty_state.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/admin/table_header.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/admin_genre_model.dart';
import '../viewmodels/genres_viewmodel.dart';
import '../widgets/add_edit_genre_dialog.dart';

class GenresPage extends StatefulWidget {
  const GenresPage({super.key, required this.viewModel});

  final GenresViewModel viewModel;

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
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

  Future<void> _openEditor([AdminGenreModel? genre]) async {
    final wasSaved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditGenreDialog(
        viewModel: widget.viewModel,
        genre: genre,
      ),
    );

    if (!mounted || wasSaved != true) {
      return;
    }

    final message = genre == null
        ? 'Genre was added successfully.'
        : 'Genre was updated successfully.';
    _showSnackBar(message, isError: false);
  }

  Future<void> _deleteGenre(AdminGenreModel genre) async {
    final shouldDelete = await _confirmDeletion(
      title: 'Delete Genre',
      message:
          'Are you sure you want to permanently delete "${genre.name}"?',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final result = await widget.viewModel.deleteGenre(genre);
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<void>():
        _showSnackBar(
          'Genre "${genre.name}" was deleted successfully.',
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
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hintText: 'Search genres by name...',
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
                        columns: ['Genre Name', 'Action'],
                      ),
                      Expanded(
                        child: viewModel.genres.isEmpty
                            ? const AdminEmptyState('No genres found.')
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                itemCount: viewModel.genres.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final genre = viewModel.genres[index];
                                  return _GenreRow(
                                    genre: genre,
                                    isDeleting:
                                        viewModel.deletingGenreId == genre.id,
                                    onEdit: () => _openEditor(genre),
                                    onDelete: () => _deleteGenre(genre),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _GenresFooter(
                currentPage: viewModel.currentPage,
                totalPages: viewModel.totalPages,
                totalCount: viewModel.totalCount,
                hasPreviousPage: viewModel.hasPreviousPage,
                hasNextPage: viewModel.hasNextPage,
                onPreviousPage: viewModel.loadPreviousPage,
                onNextPage: viewModel.loadNextPage,
                onAddGenre: () => _openEditor(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GenreRow extends StatelessWidget {
  const _GenreRow({
    required this.genre,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminGenreModel genre;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            genre.name,
            style: _rowTextStyle,
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

class _GenresFooter extends StatelessWidget {
  const _GenresFooter({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onAddGenre,
  });

  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onAddGenre;

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
              'Total genres: $totalCount',
              style: _footerCountTextStyle,
            ),
          ],
        ),
        AppButton(
          label: 'Add Genre',
          onPressed: onAddGenre,
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
