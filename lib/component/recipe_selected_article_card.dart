import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/article.dart';

class RecipeSelectedArticleCard extends StatelessWidget {
  const RecipeSelectedArticleCard({
    super.key,
    required this.article,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final Article article;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 4,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Texts (shop and article name)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.shop.isNotEmpty) Text(article.shop),
                  Text(
                    article.article,
                    textScaler: TextScaler.linear(
                      ThemeProvider.optionsOf<ThemeOptions>(context).cardTextScaleFactor,
                    ),
                    style: TextStyle(
                      fontWeight: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextFontWeight,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls and remove button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrease,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$quantity',
                    textScaler: TextScaler.linear(
                      ThemeProvider.optionsOf<ThemeOptions>(context).cardTextScaleFactor,
                    ),
                    style: TextStyle(
                      fontWeight: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextFontWeight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onIncrease,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onRemove,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
