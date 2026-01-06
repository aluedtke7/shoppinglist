import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/theme_options.dart';
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
    final scale = ThemeProvider.optionsOf<ThemeOptions>(context).cardTextScaleFactor;
    final weight = ThemeProvider.optionsOf<ThemeOptions>(context).cardTextFontWeight;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          width: double.maxFinite,
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      textScaler: TextScaler.linear(scale),
                      style: TextStyle(fontWeight: weight),
                    ),
                  ),
                  Text(
                    i18n(context).com_num_articles(articleCount),
                  ),
                ],
              ),
              if (recipe.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(recipe.notes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
