import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/admin_book_model.dart';
import '../../data/models/book_assets_model.dart';
import '../../data/models/picked_file_payload.dart';
import '../viewmodels/books_viewmodel.dart';

class AddEditBookDialog extends StatefulWidget {
  const AddEditBookDialog({
    super.key,
    required this.viewModel,
    required this.book,
  });

  final BooksViewModel viewModel;
  final AdminBookModel? book;

  @override
  State<AddEditBookDialog> createState() => _AddEditBookDialogState();
}

class _AddEditBookDialogState extends State<AddEditBookDialog> {
  static const int _minPdfBytes = 1 * 1024 * 1024;
  static const int _maxPdfBytes = 100 * 1024 * 1024;
  static const int _maxImageBytes = 10 * 1024 * 1024;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final Set<String> _selectedGenreIds;

  String? _selectedAuthorId;
  String? _titleError;
  String? _authorError;
  String? _genreError;
  String? _descriptionError;
  String? _priceError;
  String? _imageError;
  String? _pdfError;
  PickedFilePayload? _imageFile;
  PickedFilePayload? _pdfFile;
  Failure? _failure;
  bool _loadingAssets = false;
  String _imageLink = '';
  String _pdfLink = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.book?.amount.toStringAsFixed(2) ?? '',
    );
    _selectedAuthorId = widget.book?.authorId;
    _selectedGenreIds = <String>{...?widget.book?.genreIds};
    _loadAssets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    if (widget.book == null) {
      return;
    }

    setState(() => _loadingAssets = true);

    final result = await widget.viewModel.loadAssets(widget.book!.id);
    if (result is Success<BookAssetsModel>) {
      _imageLink = result.value.imageLink ?? '';
      _pdfLink = result.value.pdfLink ?? '';
    } else if (result is ErrorResult<BookAssetsModel>) {
      final error = result.failure;
      _failure = error is Failure ? error : Failure(message: error.toString());
    }

    if (mounted) {
      setState(() => _loadingAssets = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    final file = result?.files.single;
    if (file?.bytes == null || file?.name == null) {
      return;
    }

    final bytes = file!.bytes!;
    if (bytes.lengthInBytes > _maxImageBytes) {
      setState(() {
        _imageFile = null;
        _imageError =
            'Selected image is ${_formatFileSize(bytes.lengthInBytes)}. Maximum allowed size is 10 MB.';
        _failure = null;
      });
      return;
    }

    setState(() {
      _imageFile = PickedFilePayload.fromPicked(name: file.name, bytes: bytes);
      _imageError = null;
      _failure = null;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );

    final file = result?.files.single;
    if (file?.bytes == null || file?.name == null) {
      return;
    }

    final bytes = file!.bytes!;
    if (bytes.lengthInBytes < _minPdfBytes ||
        bytes.lengthInBytes > _maxPdfBytes) {
      setState(() {
        _pdfFile = null;
        _pdfError =
            'Selected PDF is ${_formatFileSize(bytes.lengthInBytes)}. Allowed range is 1 MB to 100 MB.';
        _failure = null;
      });
      return;
    }

    setState(() {
      _pdfFile = PickedFilePayload.fromPicked(name: file.name, bytes: bytes);
      _pdfError = null;
      _failure = null;
    });
  }

  bool _validateForm() {
    final normalizedTitle = _titleController.text.trim();
    final normalizedDescription = _descriptionController.text.trim();
    final normalizedPrice = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final imageTooLarge =
        _imageFile != null && _imageFile!.bytes.lengthInBytes > _maxImageBytes;
    final pdfOutsideAllowedRange = _pdfFile != null &&
        (_pdfFile!.bytes.lengthInBytes < _minPdfBytes ||
            _pdfFile!.bytes.lengthInBytes > _maxPdfBytes);
    final hasImage = _imageFile != null || _imageLink.trim().isNotEmpty;
    final hasPdf = _pdfFile != null || _pdfLink.trim().isNotEmpty;

    setState(() {
      _titleError = normalizedTitle.isEmpty ? 'Book name is required.' : null;
      _authorError = _selectedAuthorId == null ? 'Author is required.' : null;
      _genreError = _selectedGenreIds.isEmpty
          ? 'Select at least one genre.'
          : null;
      _descriptionError = normalizedDescription.isEmpty
          ? 'Description is required.'
          : null;
      _priceError = normalizedPrice == null || normalizedPrice <= 0
          ? 'Enter a valid price.'
          : null;
      _imageError = !hasImage
          ? 'Book image is required.'
          : imageTooLarge
              ? 'Selected image is ${_formatFileSize(_imageFile!.bytes.lengthInBytes)}. Maximum allowed size is 10 MB.'
              : null;
      _pdfError = !hasPdf
          ? 'Book PDF is required.'
          : pdfOutsideAllowedRange
              ? 'Selected PDF is ${_formatFileSize(_pdfFile!.bytes.lengthInBytes)}. Allowed range is 1 MB to 100 MB.'
              : null;
      _failure = null;
    });

    return _titleError == null &&
        _authorError == null &&
        _genreError == null &&
        _descriptionError == null &&
        _priceError == null &&
        _imageError == null &&
        _pdfError == null;
  }

  Future<void> _submit() async {
    if (!_validateForm()) {
      return;
    }

    final result = await widget.viewModel.saveBook(
      existingBook: widget.book,
      title: _titleController.text,
      description: _descriptionController.text,
      authorId: _selectedAuthorId!,
      genreIds: _selectedGenreIds.toList(),
      priceText: _priceController.text,
      imageLink: _imageLink,
      pdfLink: _pdfLink,
      imageFile: _imageFile,
      pdfFile: _pdfFile,
    );

    if (result is Success<void>) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (result is ErrorResult<void>) {
      if (!mounted) {
        return;
      }

      final error = result.failure;
      setState(
        () => _failure =
            error is Failure ? error : Failure(message: error.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
            child: Container(
              width: 420,
              decoration: BoxDecoration(
                color: desktopPrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.book == null ? 'ADD NEW BOOK' : 'EDIT BOOK',
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
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _modalLabel('Book Name'),
                          AppTextField(
                            controller: _titleController,
                            hintText: 'Enter book name',
                            errorText: _titleError,
                            onChanged: (_) {
                              if (_titleError != null || _failure != null) {
                                setState(() {
                                  _titleError = null;
                                  _failure = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _modalLabel('Author'),
                          _authorDropdown(),
                          if (_authorError != null) _errorText(_authorError!),
                          const SizedBox(height: 12),
                          _modalLabel('Genres'),
                          _genreSelector(),
                          if (_genreError != null) _errorText(_genreError!),
                          const SizedBox(height: 10),
                          _modalLabel('Description'),
                          AppTextField(
                            controller: _descriptionController,
                            hintText: 'Enter book description',
                            maxLines: 4,
                            errorText: _descriptionError,
                            onChanged: (_) {
                              if (_descriptionError != null ||
                                  _failure != null) {
                                setState(() {
                                  _descriptionError = null;
                                  _failure = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _modalLabel('Price'),
                          AppTextField(
                            controller: _priceController,
                            hintText: '0.00',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            errorText: _priceError,
                            onChanged: (_) {
                              if (_priceError != null || _failure != null) {
                                setState(() {
                                  _priceError = null;
                                  _failure = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          _modalLabel('Photo'),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                            label: Text(
                              _imageFile?.name ??
                                  (_imageLink.isEmpty
                                      ? 'Choose image file'
                                      : _imageLink),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (_imageError != null) _errorText(_imageError!),
                          const SizedBox(height: 12),
                          _modalLabel('PDF file'),
                          TextButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                            label: Text(
                              _pdfFile?.name ??
                                  (_pdfLink.isEmpty
                                      ? 'Choose PDF file'
                                      : _pdfLink),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (_pdfError != null) _errorText(_pdfError!),
                          if (_loadingAssets) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Loading existing assets...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                          if (widget.viewModel.isSaving) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.viewModel.savingStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: widget.viewModel.uploadProgress,
                                minHeight: 10,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(widget.viewModel.uploadProgress * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                              onPressed:
                                  widget.viewModel.isSaving || _loadingAssets
                                  ? null
                                  : _submit,
                              width: 132,
                              isLoading: widget.viewModel.isSaving,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _authorDropdown() {
    if (widget.viewModel.authors.isEmpty) {
      return const Text(
        'No authors available. Create an author first.',
        style: TextStyle(
          color: Color(0xFFFFD4D4),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedAuthorId,
      dropdownColor: desktopPrimaryLight,
      decoration: _inputDecoration('Select author'),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      items: widget.viewModel.authors
          .map(
            (author) => DropdownMenuItem<String>(
              value: author.id,
              child: Text(
                author.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedAuthorId = value;
          _authorError = null;
          _failure = null;
        });
      },
    );
  }

  Widget _genreSelector() {
    if (widget.viewModel.genres.isEmpty) {
      return const Text(
        'No genres available.',
        style: TextStyle(
          color: Color(0xFFFFD4D4),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.viewModel.genres.map((genre) {
          final isSelected = _selectedGenreIds.contains(genre.id);
          return FilterChip(
            label: Text(genre.name),
            selected: isSelected,
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            labelStyle: TextStyle(
              color: isSelected ? desktopPrimary : Colors.white,
              fontWeight: FontWeight.w700,
            ),
            checkmarkColor: desktopPrimary,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedGenreIds.add(genre.id);
                } else {
                  _selectedGenreIds.remove(genre.id);
                }

                _genreError = null;
                _failure = null;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFFD4D4),
          fontSize: 13,
          fontWeight: FontWeight.w600,
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

  String _formatFileSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }
}
