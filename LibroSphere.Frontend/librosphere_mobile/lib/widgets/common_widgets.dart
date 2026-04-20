import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../data/models/book_model.dart';

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.rectangular = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;
  final bool rectangular;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 38 : 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rectangular ? 8 : 28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class RoundedInput extends StatelessWidget {
  const RoundedInput({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.dense = false,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final bool dense;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF3F1F8),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: dense ? 14 : 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class FormMessage extends StatelessWidget {
  const FormMessage({
    super.key,
    required this.message,
    this.color = const Color(0xFFB42318),
  });

  final String? message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message!,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class CenteredLoadingIndicator extends StatelessWidget {
  const CenteredLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.leadingIcon = Icons.chevron_left_rounded,
  });

  final String title;
  final int? count;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final label = count == null ? title : '$title ($count)';

    return Row(
      children: [
        Icon(leadingIcon, color: brandBlue, size: 28),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class InfoStateView extends StatelessWidget {
  const InfoStateView({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 32),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
        ),
      ],
    );
  }
}

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFEAF2FF),
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
                Icons.menu_book_rounded,
                color: Colors.blue.shade200,
                size: width * 0.46,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => Icon(
                  Icons.menu_book_rounded,
                  color: Colors.blue.shade200,
                  size: width * 0.46,
                ),
              ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 20});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: size,
          color: index < filled ? brandBlue : Colors.black87,
        );
      }),
    );
  }
}

class MobileBottomNavigation extends StatelessWidget {
  const MobileBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.embedded = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      margin: EdgeInsets.fromLTRB(18, embedded ? 0 : 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: brandBlue,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.home_outlined,
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavIcon(
            icon: Icons.menu_book_outlined,
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavIcon(
            icon: Icons.shopping_cart_outlined,
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.bookmark_border_rounded,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );

    return embedded ? bar : SafeArea(top: false, child: bar);
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: active ? Colors.white : const Color(0xB4D3E6FF),
        size: 31,
      ),
    );
  }
}

class SearchBarCard extends StatelessWidget {
  const SearchBarCard({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0x0B000000), blurRadius: 12),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: brandBlue,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/librosphere_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Search for a book',
                  ),
                ),
              ),
              if (value.text.trim().isNotEmpty)
                InkWell(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded, color: Colors.black54),
                  ),
                ),
              InkWell(
                onTap: () => onSubmitted(controller.text),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.search, color: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NewestBookTile extends StatelessWidget {
  const NewestBookTile({
    super.key,
    required this.book,
    required this.authorName,
    required this.rating,
    required this.onOpen,
    required this.onWishlist,
  });

  final BookModel book;
  final String authorName;
  final double rating;
  final VoidCallback onOpen;
  final VoidCallback onWishlist;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(imageUrl: book.imageLink, width: 84, height: 124, radius: 0),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(authorName, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  StarRow(rating: rating),
                  const SizedBox(width: 6),
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: PrimaryPillButton(
                      label: 'Open',
                      compact: true,
                      onPressed: onOpen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onWishlist,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: brandBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
