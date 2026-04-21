import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../data/models/author_model.dart';
import '../data/models/genre_model.dart';

class BookFilterResult {
  final String? authorId;
  final String? authorName;
  final String? genreId;
  final String? genreName;
  final double? minPrice;
  final double? maxPrice;

  BookFilterResult({
    this.authorId,
    this.authorName,
    this.genreId,
    this.genreName,
    this.minPrice,
    this.maxPrice,
  });

  bool get hasFilters =>
      authorId != null || genreId != null || minPrice != null || maxPrice != null;
}

class BookFilterDialog extends StatefulWidget {
  const BookFilterDialog({
    super.key,
    required this.authors,
    required this.genres,
    this.initialAuthorId,
    this.initialGenreId,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  final List<AuthorModel> authors;
  final List<GenreModel> genres;
  final String? initialAuthorId;
  final String? initialGenreId;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  @override
  State<BookFilterDialog> createState() => _BookFilterDialogState();
}

class _BookFilterDialogState extends State<BookFilterDialog> {
  String? _selectedAuthorId;
  String? _selectedGenreId;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAuthorId = widget.initialAuthorId;
    _selectedGenreId = widget.initialGenreId;
    if (widget.initialMinPrice != null) {
      _minPriceController.text = widget.initialMinPrice!.toStringAsFixed(0);
    }
    if (widget.initialMaxPrice != null) {
      _maxPriceController.text = widget.initialMaxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    final author = widget.authors.firstWhere(
      (a) => a.id == _selectedAuthorId,
      orElse: () => AuthorModel(id: '', name: ''),
    );
    final genre = widget.genres.firstWhere(
      (g) => g.id == _selectedGenreId,
      orElse: () => GenreModel(id: '', name: ''),
    );

    final minPriceText = _minPriceController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();

    Navigator.of(context).pop(BookFilterResult(
      authorId: _selectedAuthorId,
      authorName: _selectedAuthorId != null ? author.name : null,
      genreId: _selectedGenreId,
      genreName: _selectedGenreId != null ? genre.name : null,
      minPrice: minPriceText.isNotEmpty ? double.tryParse(minPriceText) : null,
      maxPrice: maxPriceText.isNotEmpty ? double.tryParse(maxPriceText) : null,
    ));
  }

  void _clear() {
    Navigator.of(context).pop(BookFilterResult());
  }

  String _getAuthorDisplayName(AuthorModel author) {
    return author.name.isEmpty ? 'Unknown Author' : author.name;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Books',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Author'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAuthorId,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Any Author'),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Any Author'),
                        ),
                      ),
                      ...widget.authors.map((author) => DropdownMenuItem(
                            value: author.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(_getAuthorDisplayName(author)),
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedAuthorId = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Genre'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGenreId,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Any Genre'),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Any Genre'),
                        ),
                      ),
                      ...widget.genres.map((genre) => DropdownMenuItem(
                            value: genre.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(genre.name),
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedGenreId = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Price Range'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        prefixText: '\$ ',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlueDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: brandBlueDark,
      ),
    );
  }
}
