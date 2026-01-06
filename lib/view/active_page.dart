import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
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
import 'package:theme_provider/theme_provider.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/component/no_article_widget.dart';

class ActivePage extends StatefulWidget {
  const ActivePage({super.key});

  static const routeName = '/active';

  @override
  State<ActivePage> createState() => _ActivePageState();
}

class _ActivePageState extends State<ActivePage> with WidgetsBindingObserver {
  var _isLoading = false;
  PocketBaseProvider? pbp;

  @override
  void initState() {
    super.initState();
    pbp = Provider.of<PocketBaseProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    _fetchAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pbp?.unsubscribeActive();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('Lifecycle changed: $state');
    if (state == AppLifecycleState.resumed) {
      pbp?.doHealthCheck();
      _fetchActive();
    }
  }

  Future<void> _fetchActive() async {
    return pbp?.fetchActive();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
    });
    try {
      pbp?.subscribeActive();
      await Future.wait([
        _fetchActive(),
        pbp!.fetchAllRecipes(),
      ]);
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
    page = SelPage.activeList;

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_active_title),
      drawer: const SlappDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: Container(
          decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _isLoading
                    ? const SizedBox(height: 50, width: 50, child: CircularProgressIndicator())
                    : Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SlidableAutoCloseBehavior(
                            child: pbp.activeArticles.isEmpty
                                ? const NoArticleWidget(height: 1.5)
                                : ListView.builder(
                                    itemBuilder: (ctx, idx) {
                                      final itm = pbp.activeArticles[idx];
                                      return Slidable(
                                        groupTag: '0',
                                        startActionPane: ActionPane(
                                          motion: const StretchMotion(),
                                          children: [
                                            SlidableAction(
                                              autoClose: false,
                                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                                              padding: const EdgeInsets.all(8),
                                              backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                  .slideBtnBackgroundColor(context),
                                              foregroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                  .slideBtnForegroundColor(context),
                                              onPressed: (context) async {
                                                itm.amount = min(12, itm.amount + 1);
                                                try {
                                                  await pbp.updateArticle(itm);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    Statics.showErrorSnackbar(context, e);
                                                  }
                                                }
                                              },
                                              icon: Icons.add,
                                            ),
                                            SlidableAction(
                                              autoClose: false,
                                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                                              padding: const EdgeInsets.all(8),
                                              backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                  .slideBtnBackgroundColor(context),
                                              foregroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                  .slideBtnForegroundColor(context),
                                              onPressed: (context) async {
                                                itm.amount = max(1, itm.amount - 1);
                                                try {
                                                  await pbp.updateArticle(itm);
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    Statics.showErrorSnackbar(context, e);
                                                  }
                                                }
                                              },
                                              icon: Icons.remove,
                                            ),
                                          ],
                                        ),
                                        endActionPane: ActionPane(motion: const StretchMotion(), children: [
                                          SlidableAction(
                                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                .slideBtnBackgroundColor(context),
                                            foregroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                .slideBtnForegroundColor(context),
                                            onPressed: (context) {
                                              Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: itm);
                                            },
                                            icon: Icons.edit,
                                          ),
                                          SlidableAction(
                                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                                            padding: const EdgeInsets.all(8),
                                            backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                .slideBtnBackgroundColor(context),
                                            foregroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                                .slideBtnForegroundColor(context),
                                            onPressed: (context) {
                                              final newItm = Article(
                                                active: true,
                                                amount: 1,
                                                shop: itm.shop,
                                                article: itm.article,
                                              );
                                              Navigator.pushNamed(
                                                context,
                                                ArticleEditPage.routeName,
                                                arguments: newItm,
                                              );
                                            },
                                            icon: Icons.copy,
                                          ),
                                        ]),
                                        child: Builder(builder: (c) {
                                          return GestureDetector(
                                            onDoubleTap: () {
                                              pbp.toggleinCart(itm);
                                            },
                                            onLongPress: () {
                                              Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: itm);
                                            },
                                            child: ArticleCard(
                                              article: itm,
                                              isArticleList: false,
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                    itemCount: pbp.activeArticles.length,
                                  ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'end_shopping',
            onPressed: () {
              Statics.showEndShoppingDialog(context, pbp);
            },
            tooltip: i18n(context).drawer_end_shopping,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: ImageIcon(
              size: 24,
              AssetImage('assets/race_flag.png'),
            ),
          ),
          FloatingActionButton(
            heroTag: 'select_recipe',
            onPressed: () async {
              // ensure recipes loaded
              await pbp.fetchAllRecipes();
              if (!context.mounted) return;
              final Recipe? selected = await Statics.selectRecipeDialog(context, pbp);
              if (selected != null) {
                await pbp.selectRecipeSetInCart(selected.id);
              }
            },
            tooltip: i18n(context).p_recipes_select,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: const Icon(Icons.menu_book),
          ),
          FloatingActionButton(
            heroTag: 'add_item',
            onPressed: () {
              pbp.clearSearchList();
              Statics.searchForArticle(context, pbp).then((value) {
                if (value != null) {
                  value.active = true;
                  value.amount = max(1, value.amount);
                  pbp.updateArticle(value);
                }
              });
            },
            tooltip: i18n(context).p_active_tooltip,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
