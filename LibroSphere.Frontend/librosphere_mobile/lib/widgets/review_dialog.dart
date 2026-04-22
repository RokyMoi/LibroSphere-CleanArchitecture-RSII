import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/ui/app_feedback.dart';
import '../data/models/book_model.dart';
import '../features/session/presentation/session_scope.dart';
import 'common_widgets.dart';

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, required this.book});

  final BookModel book;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _textController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _commentError;
  String? _formError;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _validate() {
    final comment = _textController.text.trim();

    setState(() {
      _commentError = comment.isEmpty
          ? 'Please share a few words about this book.'
          : null;
      _formError = null;
    });

    return _commentError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await SessionScope.read(context).submitReview(
        bookId: widget.book.id,
        rating: _rating,
        comment: _textController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _formError = formatErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = math.max(
      320.0,
      mediaQuery.size.height - keyboardHeight - 32,
    );
    final dialogWidth = math.min(mediaQuery.size.width - 24, 460.0);
    final compactMode = keyboardHeight > 0;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(12, 12, 12, keyboardHeight + 12),
        child: Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: math.min(availableHeight, 620),
              ),
              decoration: BoxDecoration(
                color: brandBlue,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Review ${widget.book.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(false),
                          borderRadius: BorderRadius.circular(24),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.cancel_outlined,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stars:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Wrap(
                              spacing: 2,
                              children: List.generate(5, (index) {
                                final filled = index < _rating;
                                return IconButton(
                                  constraints: const BoxConstraints.tightFor(
                                    width: 38,
                                    height: 38,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      setState(() => _rating = index + 1),
                                  icon: Icon(
                                    Icons.star,
                                    color: filled ? brandBlue : Colors.black87,
                                    size: 30,
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Text:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textController,
                            maxLines: compactMode ? 4 : 6,
                            minLines: compactMode ? 3 : 5,
                            textInputAction: TextInputAction.newline,
                            onChanged: (_) {
                              if (_commentError != null || _formError != null) {
                                setState(() {
                                  _commentError = null;
                                  _formError = null;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'What stood out to you in this book?',
                              errorText: _commentError,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FormMessage(message: _formError, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: brandBlueDark,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF0E4A90)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_submitting ? 'Submitting...' : 'Submit'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
