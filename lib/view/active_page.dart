import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/component/active_article_tile.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/slapp_navigation_bar.dart';
import 'package:shoppinglist/component/snackbars.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/model/shop_group.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/article_edit_page.dart';
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
    pbp = context.read<PocketBaseProvider>();
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
    if (!mounted) return;
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
        showErrorSnackbar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addArticle(PocketBaseProvider pbp) {
    pbp.clearSearchList();
    searchForArticle(context, pbp).then((value) {
      if (value != null) {
        final updatedValue = value.copyWith(
          active: true,
          amount: max(1, value.amount),
        );
        pbp.updateArticle(updatedValue);
      }
    });
  }

  Future<void> _selectRecipe(PocketBaseProvider pbp) async {
    // ensure recipes loaded
    await pbp.fetchAllRecipes();
    if (!mounted) return;
    final Recipe? selected = await selectRecipeDialog(context, pbp);
    if (selected != null) {
      await pbp.selectRecipeSetInCart(selected.id);
    }
  }

  Future<void> _updateAmount(BuildContext context, PocketBaseProvider pbp, Article itm, int amount) async {
    try {
      await pbp.updateArticle(itm.copyWith(amount: amount));
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = context.watch<PocketBaseProvider>();
    page = SelPage.activeList;
    final scheme = Theme.of(context).colorScheme;
    final groups = groupByShop(pbp.activeArticles);

    SlidableAction themedAction({
      required IconData icon,
      required void Function(BuildContext) onPressed,
      bool autoClose = true,
      bool filled = false,
    }) {
      return SlidableAction(
        autoClose: autoClose,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: EdgeInsets.zero,
        backgroundColor: filled ? scheme.primary : scheme.primaryContainer,
        foregroundColor: filled ? scheme.onPrimary : scheme.primary,
        onPressed: onPressed,
        icon: icon,
      );
    }

    Widget articleRow(Article itm) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Slidable(
          groupTag: '0',
          startActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              themedAction(
                autoClose: false,
                icon: Icons.add,
                onPressed: (context) => _updateAmount(context, pbp, itm, min(12, itm.amount + 1)),
              ),
              themedAction(
                autoClose: false,
                icon: Icons.remove,
                onPressed: (context) => _updateAmount(context, pbp, itm, max(1, itm.amount - 1)),
              ),
            ],
          ),
          endActionPane: ActionPane(motion: const StretchMotion(), children: [
            themedAction(
              filled: true,
              icon: Icons.edit_outlined,
              onPressed: (context) {
                Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: itm);
              },
            ),
            themedAction(
              icon: Icons.content_copy_outlined,
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
            ),
          ]),
          child: GestureDetector(
            onLongPress: () {
              Navigator.pushNamed(context, ArticleEditPage.routeName, arguments: itm);
            },
            child: ActiveArticleTile(
              article: itm,
              onToggleInCart: () => pbp.toggleinCart(itm),
            ),
          ),
        ),
      );
    }

    Widget section(String label, List<Article> articles) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(label: label, count: articles.length),
            ...articles.map(articleRow),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_active_title),
      bottomNavigationBar: const SlappNavigationBar(selectedIndex: 0),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : pbp.activeArticles.isEmpty
                // Scrollable so pull-to-refresh still works, filling the page so the hint is centered.
                ? const CustomScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: NoArticleWidget(height: 1.5),
                      ),
                    ],
                  )
                : SlidableAutoCloseBehavior(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Bottom padding keeps the last rows reachable above the stacked floating action buttons.
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 232),
                      children: [
                        _ProgressHeader(inCart: groups.inCart.length, total: pbp.activeArticles.length),
                        const SizedBox(height: 24),
                        for (final group in groups.open)
                          section(group.shop.isEmpty ? i18n(context).p_active_no_shop : group.shop, group.articles),
                        if (groups.inCart.isNotEmpty) section(i18n(context).p_active_in_cart, groups.inCart),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_item',
            onPressed: () => _addArticle(pbp),
            tooltip: i18n(context).p_active_tooltip,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'select_recipe',
            onPressed: () => _selectRecipe(pbp),
            tooltip: i18n(context).p_recipes_select,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: const Icon(Icons.menu_book),
          ),
          FloatingActionButton(
            heroTag: 'end_shopping',
            onPressed: () {
              showEndShoppingDialog(context, pbp);
            },
            tooltip: i18n(context).drawer_end_shopping,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            child: ImageIcon(
              size: 24,
              AssetImage('assets/race_flag.png'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.inCart, required this.total});

  final int inCart;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              i18n(context).p_active_progress(inCart, total),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              i18n(context).p_active_open(total - inCart),
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        LinearProgressIndicator(
          value: inCart / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: style),
          Text('$count', style: style),
        ],
      ),
    );
  }
}
