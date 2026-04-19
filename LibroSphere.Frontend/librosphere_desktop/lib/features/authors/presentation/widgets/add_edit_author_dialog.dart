import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../books/data/models/admin_author_model.dart';
import '../viewmodels/authors_viewmodel.dart';

class AddEditAuthorDialog extends StatefulWidget {
  const AddEditAuthorDialog({
    super.key,
    required this.viewModel,
    required this.author,
  });

  final AuthorsViewModel viewModel;
  final AdminAuthorModel? author;

  @override
  State<AddEditAuthorDialog> createState() => _AddEditAuthorDialogState();
}

class _AddEditAuthorDialogState extends State<AddEditAuthorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _biographyController;

  String? _nameError;
  String? _biographyError;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.author?.name ?? '');
    _biographyController = TextEditingController(
      text: widget.author?.biography ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  bool _validate() {
    final normalizedName = _nameController.text.trim();
    final normalizedBiography = _biographyController.text.trim();

    setState(() {
      _nameError = normalizedName.isEmpty ? 'Author name is required.' : null;
      _biographyError = normalizedBiography.isEmpty
          ? 'Biography is required.'
          : null;
      _failure = null;
    });

    return _nameError == null && _biographyError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      return;
    }

    final result = await widget.viewModel.saveAuthor(
      existingAuthor: widget.author,
      name: _nameController.text,
      biography: _biographyController.text,
    );

    if (result is Success<void>) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (result is ErrorResult<void> && mounted) {
      final error = result.failure;
      setState(() {
        _failure = error is Failure
            ? error
            : Failure(message: error.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(
          color: desktopPrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.author == null ? 'ADD AUTHOR' : 'EDIT AUTHOR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _modalLabel('Author Name'),
              AppTextField(
                controller: _nameController,
                hintText: 'Enter author name',
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null || _failure != null) {
                    setState(() {
                      _nameError = null;
                      _failure = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _modalLabel('Biography'),
              AppTextField(
                controller: _biographyController,
                hintText: 'Enter biography',
                maxLines: 6,
                errorText: _biographyError,
                onChanged: (_) {
                  if (_biographyError != null || _failure != null) {
                    setState(() {
                      _biographyError = null;
                      _failure = null;
                    });
                  }
                },
              ),
              if (_failure != null) ...[
                const SizedBox(height: 14),
                Text(
                  _failure!.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Align(
                child: AppButton(
                  label: 'SAVE',
                  onPressed: widget.viewModel.isSaving ? null : _submit,
                  width: 132,
                  isLoading: widget.viewModel.isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
