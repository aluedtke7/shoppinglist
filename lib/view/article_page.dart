import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import 'package:shoppinglist/component/debounced_search_field.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_navigation_bar.dart';
import 'package:shoppinglist/component/snackbars.dart';
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
        showErrorSnackbar(context, e);
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
    final filteredArticles = pbp.allArticles
        .where((art) =>
            art.shop.toUpperCase().contains(_searchFor.toUpperCase()) ||
            art.article.toUpperCase().contains(_searchFor.toUpperCase()))
        .toList();
    page = SelPage.articleList;

    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color;
    const radius = Radius.circular(20);

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_articles_title),
      bottomNavigationBar: const SlappNavigationBar(selectedIndex: 1),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  DebouncedSearchField(
                    autofocus: true,
                    hintText: i18n(context).p_articles_search_hint,
                    onChanged: (text) => setState(() => _searchFor = text),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          i18n(context).com_num_articles(filteredArticles.length),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          i18n(context).p_articles_tap_hint,
                          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: filteredArticles.length,
                      separatorBuilder: (ctx, idx) => ColoredBox(
                        color: cardColor ?? scheme.surface,
                        child: const Divider(indent: 16, endIndent: 16),
                      ),
                      itemBuilder: (ctx, idx) {
                        final article = filteredArticles[idx];
                        return ListTile(
                          minTileHeight: 60,
                          tileColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: idx == 0 ? radius : Radius.zero,
                              bottom: idx == filteredArticles.length - 1 ? radius : Radius.zero,
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
                          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                          onTap: () {
                            Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: article);
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: Article());
        },
        icon: const Icon(Icons.add),
        label: Text(i18n(context).p_article_add),
      ),
    );
  }
}
