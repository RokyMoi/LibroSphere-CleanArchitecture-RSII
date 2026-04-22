import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../data/models/book_model.dart';
import 'app_bottom_navigation.dart';

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
    this.inputFormatters,
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
  final List<TextInputFormatter>? inputFormatters;

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
      inputFormatters: inputFormatters,
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

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 14,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class BookListSkeleton extends StatelessWidget {
  const BookListSkeleton({
    super.key,
    this.showHeader = true,
    this.itemCount = 4,
  });

  final bool showHeader;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final totalItems = itemCount + (showHeader ? 2 : 0);

    return LoadingSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          if (showHeader && index == 0) {
            return const SkeletonBox(height: 28, width: 160, radius: 12);
          }
          if (showHeader && index == 1) {
            return const SizedBox(height: 26);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 128, width: 88, radius: 8),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 20, width: double.infinity, radius: 10),
                      SizedBox(height: 8),
                      SkeletonBox(height: 16, width: 140, radius: 10),
                      SizedBox(height: 18),
                      SkeletonBox(height: 38, width: 110, radius: 20),
                      SizedBox(height: 12),
                      SkeletonBox(height: 18, width: 90, radius: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: const [
          SkeletonBox(height: 56, radius: 28),
          SizedBox(height: 26),
          SkeletonBox(height: 28, width: 210, radius: 12),
          SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Row(
              children: [
                Expanded(child: SkeletonBox(height: 190, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 190, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 190, radius: 16)),
              ],
            ),
          ),
          SizedBox(height: 24),
          SkeletonBox(height: 28, width: 120, radius: 12),
          SizedBox(height: 18),
        ],
      ),
    );
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
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width * devicePixelRatio).round();
    final cacheHeight = (height * devicePixelRatio).round();

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
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth > 0 ? cacheWidth : null,
                memCacheHeight: cacheHeight > 0 ? cacheHeight : null,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
                maxWidthDiskCache: cacheWidth > 0 ? cacheWidth * 2 : null,
                maxHeightDiskCache: cacheHeight > 0 ? cacheHeight * 2 : null,
                errorWidget: (context, url, error) => Icon(
                  Icons.menu_book_rounded,
                  color: Colors.blue.shade200,
                  size: width * 0.46,
                ),
                placeholder: (context, url) => Container(
                  color: const Color(0xFFEAF2FF),
                ),
              ),
      ),
    );
  }
}

class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.backgroundColor,
    required this.fallback,
  });

  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl?.trim();
    final size = radius * 2;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: fallback,
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          errorWidget: (context, url, error) => Center(child: fallback),
          placeholder: (context, url) => const SizedBox.shrink(),
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
    return AppBottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      embedded: embedded,
      showNotifications: false,
      unreadCount: 0,
      onBellTap: null,
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
