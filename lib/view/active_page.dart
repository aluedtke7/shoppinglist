import 'dart:math';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/article_card.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_drawer.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';

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
      await Future.wait([_fetchActive()]);
    } on ClientException catch (e) {
      Statics.showErrorSnackbar(context, e);
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
      appBar: SlappAppBar(title: AppLocalizations.of(context)!.p_active_title),
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
                            child: ListView.builder(
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
                                        onPressed: (context) {
                                          itm.amount = min(12, itm.amount + 1);
                                          pbp.updateArticle(itm).catchError((e) {
                                            Statics.showErrorSnackbar(context, e);
                                          });
                                        },
                                        icon: Icons.add,
                                      ),
                                      SlidableAction(
                                        autoClose: false,
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                        padding: const EdgeInsets.all(8),
                                        backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                            .slideBtnBackgroundColor(context),
                                        onPressed: (context) {
                                          itm.amount = max(1, itm.amount - 1);
                                          pbp.updateArticle(itm).catchError((e) {
                                            Statics.showErrorSnackbar(context, e);
                                          });
                                        },
                                        icon: Icons.remove,
                                      ),
                                      SlidableAction(
                                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                                        padding: const EdgeInsets.all(8),
                                        backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                            .slideBtnBackgroundColor(context),
                                        onPressed: (context) {
                                          Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: itm);
                                        },
                                        icon: Icons.edit,
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(motion: const StretchMotion(), children: [
                                    SlidableAction(
                                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                                      padding: const EdgeInsets.all(8),
                                      backgroundColor: ThemeProvider.optionsOf<ThemeOptions>(context)
                                          .slideBtnBackgroundColor(context),
                                      onPressed: (context) {
                                        pbp.toggleinCart(itm).catchError((e) {
                                          Statics.showErrorSnackbar(context, e);
                                        });
                                      },
                                      icon: Icons.check,
                                    ),
                                  ]),
                                  child: Builder(builder: (c) {
                                    return GestureDetector(
                                      onDoubleTap: () {
                                        pbp.toggleinCart(itm);
                                      },
                                      onLongPress: () {
                                        Slidable.of(c)?.openStartActionPane();
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
      floatingActionButton: FloatingActionButton(
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
        tooltip: AppLocalizations.of(context)!.p_active_tooltip,
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}