import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    Key? key,
    required this.article,
    required this.isArticleList,
  }) : super(key: key);
  final Article article;
  final bool isArticleList;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: article.inCart
          ? ThemeProvider.optionsOf<ThemeOptions>(context).inCartBackgroundColor
          : Theme.of(context).cardTheme.color,
      elevation: 4,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.shop.isNotEmpty) Text(article.shop),
            Text(
              '${!isArticleList ? "${article.amount}   " : ""}${article.article}',
              textScaleFactor: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextScaleFactor,
              style: TextStyle(
                fontWeight: ThemeProvider.optionsOf<ThemeOptions>(context).cardTextFontWeight,
                decoration: article.inCart ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
