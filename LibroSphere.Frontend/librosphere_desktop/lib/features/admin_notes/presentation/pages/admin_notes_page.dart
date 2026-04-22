import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/admin/admin_empty_state.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/admin_note_model.dart';
import '../viewmodels/admin_notes_viewmodel.dart';

class AdminNotesPage extends StatefulWidget {
  const AdminNotesPage({super.key, required this.viewModel});

  final AdminNotesViewModel viewModel;

  @override
  State<AdminNotesPage> createState() => _AdminNotesPageState();
}

class _AdminNotesPageState extends State<AdminNotesPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddAdminNoteDialog(viewModel: widget.viewModel),
    );
    if (!mounted || result != true) return;
    _showSnackBar('Admin note created successfully.', isError: false);
  }

  Future<void> _deleteAdminNote(AdminNoteModel adminNote) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin Note'),
        content: Text('Delete "${adminNote.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final result = await widget.viewModel.deleteAdminNote(adminNote);
    if (!mounted) return;
    switch (result) {
      case Success<void>():
        _showSnackBar('Admin note deleted.', isError: false);
      case ErrorResult<void>(failure: final err):
        _showSnackBar(err.toString(), isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
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
        final vm = widget.viewModel;

        if (vm.isLoading) return const LoadingView();
        if (vm.failure != null) {
          return ErrorView(message: vm.failure!.message, onRetry: vm.load);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              // Header + Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AppButton(
                    label: 'Add Note',
                    onPressed: _openCreateDialog,
                    width: 140,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AdminPanel(
                  child: vm.adminNotes.isEmpty
                      ? const AdminEmptyState('No admin notes found.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.adminNotes.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final adminNote = vm.adminNotes[index];
                            return _AdminNoteRow(
                              adminNote: adminNote,
                              isDeleting:
                                  vm.deletingAdminNoteId == adminNote.id,
                              onDelete: () => _deleteAdminNote(adminNote),
                            );
                          },
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

// ─── Admin Note Row ───────────────────────────────────────────────────────────

class _AdminNoteRow extends StatelessWidget {
  const _AdminNoteRow({
    required this.adminNote,
    required this.isDeleting,
    required this.onDelete,
  });

  final AdminNoteModel adminNote;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: desktopPrimaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail
          if (adminNote.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                adminNote.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder,
              ),
            )
          else
            _placeholder,
          const SizedBox(width: 14),
          // Title + text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adminNote.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  adminNote.text,
                  style: const TextStyle(
                    color: desktopMutedForeground,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (adminNote.createdOnUtc != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatAdminDateTime(adminNote.createdOnUtc),
                      style: const TextStyle(
                        color: desktopMutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          SizedBox(
            width: 100,
            child: AppButton(
              label: 'DELETE',
              onPressed: isDeleting ? null : onDelete,
              height: 36,
              isLoading: isDeleting,
            ),
          ),
        ],
      ),
    );
  }

  static final _placeholder = Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: desktopPrimaryLight.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.article_outlined, color: Colors.white54, size: 28),
  );
}

// ─── Add Note Dialog ──────────────────────────────────────────────────────────

class _AddAdminNoteDialog extends StatefulWidget {
  const _AddAdminNoteDialog({required this.viewModel});

  final AdminNotesViewModel viewModel;

  @override
  State<_AddAdminNoteDialog> createState() => _AddAdminNoteDialogState();
}

class _AddAdminNoteDialogState extends State<_AddAdminNoteDialog> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  String? _selectedImagePath;
  String? _selectedImageName;
  String? _error;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImagePath = result.files.first.path;
        _selectedImageName = result.files.first.name;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    String imageUrl = '';

    // If image is selected, upload it first
    if (_selectedImagePath != null) {
      setState(() => _isUploadingImage = true);

      final bytes = await File(_selectedImagePath!).readAsBytes();
      final extension = _selectedImagePath!.split('.').last.toLowerCase();
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final uploadResult = await widget.viewModel.uploadAdminNoteImage(
        imageBytes: bytes,
        filename: _selectedImageName!,
        contentType: contentType,
      );

      setState(() => _isUploadingImage = false);

      if (!mounted) return;

      switch (uploadResult) {
        case Success<String>(value: final url):
          imageUrl = url;
        case ErrorResult<String>(failure: final err):
          setState(() => _error = 'Image upload failed: ${err.toString()}');
          return;
      }
    }

    final result = await widget.viewModel.createAdminNote(
      title: _titleController.text,
      text: _textController.text,
      imageUrl: imageUrl,
    );

    if (!mounted) return;

    switch (result) {
      case Success<void>():
        Navigator.of(context).pop(true);
      case ErrorResult<void>(failure: final err):
        setState(() => _error = err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isBusy = vm.isSaving || _isUploadingImage;

    return AlertDialog(
      title: const Text('Add Admin Note'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(controller: _titleController, hintText: 'Title'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _textController,
              hintText: 'Content',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            // Image picker
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isBusy ? null : _pickImage,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Choose Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: desktopPrimaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedImageName ?? 'No image selected (optional)',
                    style: TextStyle(
                      color: _selectedImageName != null
                          ? Colors.white
                          : desktopMutedForeground,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedImageName != null)
                  IconButton(
                    onPressed: isBusy
                        ? null
                        : () => setState(() {
                            _selectedImagePath = null;
                            _selectedImageName = null;
                          }),
                    icon: const Icon(Icons.clear, size: 18),
                    color: desktopMutedForeground,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFC8181), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isBusy ? null : _save,
          child: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Publish'),
        ),
      ],
    );
  }
}
