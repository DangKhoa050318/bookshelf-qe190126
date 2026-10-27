import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme.dart';

/// Star button that is "on" for favorites.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.favorite, required this.onPressed});

  final bool favorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
      isSelected: favorite,
      icon: const Icon(Icons.star_border),
      selectedIcon: const Icon(Icons.star, color: Color(0xFFF9A825)),
      onPressed: onPressed,
    );
  }
}

/// Small rounded label, e.g. a genre or a status.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: Gap.xs),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

class BookTile extends StatelessWidget {
  const BookTile({
    super.key,
    required this.book,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final Book book;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, 0, Gap.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: text.titleMedium),
                    Text(book.author, style: text.bodyMedium),
                    const SizedBox(height: Gap.xs),
                    Wrap(
                      spacing: Gap.xs,
                      runSpacing: Gap.xs,
                      children: [
                        InfoChip(label: book.genre, icon: Icons.category_outlined),
                        InfoChip(label: book.status, icon: Icons.bookmark_outline),
                      ],
                    ),
                  ],
                ),
              ),
              FavoriteButton(favorite: book.favorite, onPressed: onToggleFavorite),
              IconButton(
                tooltip: 'Open details',
                icon: const Icon(Icons.chevron_right),
                onPressed: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
