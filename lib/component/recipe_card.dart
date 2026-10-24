import 'package:flutter/material.dart';

import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/component/i18n_util.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.articleCount,
    this.onTap,
  });

  final Recipe recipe;
  final int articleCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (recipe.notes.isNotEmpty)
                      Text(
                        recipe.notes,
                        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Text(
                i18n(context).com_num_articles(articleCount),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
