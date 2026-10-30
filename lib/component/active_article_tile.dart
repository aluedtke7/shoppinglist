import 'package:flutter/material.dart';

import 'package:shoppinglist/model/article.dart';

/// One row of the shopping list: article name and amount.
class ActiveArticleTile extends StatelessWidget {
  const ActiveArticleTile({
    super.key,
    required this.article,
    required this.onToggleInCart,
  });

  final Article article;
  final VoidCallback onToggleInCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inCart = article.inCart;

    return Material(
      color: inCart ? scheme.surfaceContainerHighest : theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: inCart ? 52 : 56),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: onToggleInCart,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    article.article,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: inCart ? FontWeight.w500 : FontWeight.w600,
                      color: inCart ? scheme.onSurfaceVariant : scheme.onSurface,
                      decoration: inCart ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Amount(amount: article.amount, inCart: inCart),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.amount, required this.inCart});

  final int amount;
  final bool inCart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (inCart) {
      return Text(
        '$amount×',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$amount×',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.primary),
      ),
    );
  }
}
