import 'package:flutter/material.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/model/article.dart';

class ArticleSelectionCard extends StatelessWidget {
  const ArticleSelectionCard({
    Key? key,
    required this.article,
  }) : super(key: key);
  final Article article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // debugPrint('ArticleSelectionCard tapped: ${article.article}');
        Navigator.pop(context, article);
      },
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 4,
        child: Container(
          width: double.maxFinite,
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.shop.isNotEmpty) Text(article.shop),
              Text(
                article.article,
                textScaleFactor: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextScaleFactor,
                style: TextStyle(
                  fontWeight: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextFontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
