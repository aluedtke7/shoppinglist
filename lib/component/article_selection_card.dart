import 'package:flutter/material.dart';

import 'package:shoppinglist/model/article.dart';

/// One search result; consecutive results form one card, so only the first and last are rounded.
class ArticleSelectionCard extends StatelessWidget {
  const ArticleSelectionCard({
    super.key,
    required this.article,
    this.isFirst = false,
    this.isLast = false,
  });

  final Article article;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = Radius.circular(20);

    return ListTile(
      minTileHeight: 60,
      tileColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? radius : Radius.zero,
          bottom: isLast ? radius : Radius.zero,
        ),
      ),
      title: Text(
        article.article,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: article.shop.isEmpty
          ? null
          : Text(
              article.shop,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
      onTap: () => Navigator.pop(context, article),
    );
  }
}
