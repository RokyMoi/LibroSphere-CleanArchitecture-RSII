import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/admin_genre_model.dart';
import '../viewmodels/genres_viewmodel.dart';

class AddEditGenreDialog extends StatefulWidget {
  const AddEditGenreDialog({
    super.key,
    required this.viewModel,
    required this.genre,
  });

  final GenresViewModel viewModel;
  final AdminGenreModel? genre;

  @override
  State<AddEditGenreDialog> createState() => _AddEditGenreDialogState();
}

class _AddEditGenreDialogState extends State<AddEditGenreDialog> {
  late final TextEditingController _nameController;

  String? _nameError;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.genre?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final normalizedName = _nameController.text.trim();

    if (normalizedName.isEmpty) {
      setState(() {
        _nameError = 'Genre name is required.';
        _failure = null;
      });
      return;
    }

    final result = await widget.viewModel.saveGenre(
      existingGenre: widget.genre,
      name: normalizedName,
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
        decoration: BoxDecoration(
          color: desktopPrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.genre == null ? 'ADD GENRE' : 'EDIT GENRE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.viewModel.isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Genre Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _nameController,
                hintText: 'Enter genre name',
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
              if (_failure != null) ...[
                const SizedBox(height: 12),
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
                alignment: Alignment.center,
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
}
