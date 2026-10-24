import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shoppinglist/component/debounced_search_field.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_navigation_bar.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/model/sel_page.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/view/recipe_edit_page.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});
  static const routeName = '/recipes';

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  var _isLoading = false;
  var _searchFor = '';

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAllRecipes(PocketBaseProvider pbp) async {
    return pbp.fetchAllRecipes();
  }

  Future<void> _fetchAll() async {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.wait([_fetchAllRecipes(pbp)]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = Provider.of<PocketBaseProvider>(context, listen: true);
    final filteredRecipes =
        pbp.allRecipes.where((r) => r.name.toUpperCase().contains(_searchFor.toUpperCase())).toList();
    page = SelPage.articleList; // reuse for highlighting

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_recipes_title),
      bottomNavigationBar: const SlappNavigationBar(selectedIndex: 2),
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
                    hintText: i18n(context).p_recipes_search_hint,
                    onChanged: (text) => setState(() => _searchFor = text),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      i18n(context).com_num_recipes(filteredRecipes.length),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                      itemCount: filteredRecipes.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final rec = filteredRecipes[idx];
                        return _RecipeTile(
                          recipe: rec,
                          articleCount: pbp.recipeArticleCount[rec.id] ?? 0,
                          onTap: () {
                            Navigator.pushNamed(context, RecipeEditPage.routeName, arguments: rec);
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
          Navigator.pushNamed(context, RecipeEditPage.routeName, arguments: Recipe());
        },
        icon: const Icon(Icons.add),
        label: Text(i18n(context).p_recipes_tooltip),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.articleCount, required this.onTap});

  final Recipe recipe;
  final int articleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    return Material(
      color: Theme.of(context).cardTheme.color,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 14,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  recipe.name.isEmpty ? '?' : recipe.name.characters.first.toUpperCase(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.primary),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(recipe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    if (recipe.notes.isNotEmpty)
                      Text(recipe.notes, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                    Text(
                      i18n(context).com_num_articles(articleCount),
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
