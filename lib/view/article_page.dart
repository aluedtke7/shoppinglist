import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/article_card.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_drawer.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});
  static const routeName = '/articles';

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  var _isLoading = false;
  var _searchFor = '';

  @override
  void initState() {
    super.initState();

    _fetchAll();
  }

  Future<void> _fetchAllArticles(PocketBaseProvider pbp) async {
    return pbp.fetchAllArticles();
  }

  Future<void> _fetchAll() async {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.wait([_fetchAllArticles(pbp)]);
    } on ClientException catch (e) {
      if (mounted) {
        Statics.showErrorSnackbar(context, e);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: true);
    Timer? delayedSearch;
    final filteredArticles = pbp.allArticles
        .where((art) =>
            art.shop.toUpperCase().contains(_searchFor.toUpperCase()) ||
            art.article.toUpperCase().contains(_searchFor.toUpperCase()))
        .toList();
    page = SelPage.articleList;

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_articles_title),
      drawer: const SlappDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: Container(
          decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(labelText: i18n(context).com_search_term),
                            autofocus: true,
                            onChanged: (text) {
                              // debugPrint('Search text: $text');
                              delayedSearch?.cancel();
                              delayedSearch = Timer(const Duration(milliseconds: 750), () {
                                setState(() {
                                  _searchFor = text;
                                });
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Text(i18n(context).com_num_articles(filteredArticles.length)),
                        ),
                      ],
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(height: 50, width: 50, child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            itemBuilder: (ctx, idx) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, ArticleEditPage.routeName,
                                      arguments: filteredArticles[idx]);
                                },
                                child: ArticleCard(
                                  article: filteredArticles[idx],
                                  isArticleList: true,
                                ),
                              );
                            },
                            itemCount: filteredArticles.length,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: Article());
        },
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        tooltip: i18n(context).p_articles_tooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
