import 'package:flutter/material.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/model/article.dart';

/// One row of the shopping list: check circle, article name and amount.
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
      child: SizedBox(
        height: inCart ? 52 : 56,
        child: Row(
          children: [
            const SizedBox(width: 6),
            IconButton(
              onPressed: onToggleInCart,
              tooltip: inCart ? i18n(context).p_active_from_cart : i18n(context).p_active_to_cart,
              icon: inCart
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.primary,
                      child: Icon(Icons.check, size: 16, color: scheme.onPrimary),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                    ),
            ),
            const SizedBox(width: 2),
            Expanded(
              // Double tap only on the label, so taps on the check button are not delayed by double tap detection.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: onToggleInCart,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.article,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ],
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
