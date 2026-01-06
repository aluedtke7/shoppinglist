import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/selected_page.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_drawer.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/component/recipe_card.dart';
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
  Timer? _delayedSearch;

  @override
  void dispose() {
    _delayedSearch?.cancel();
    super.dispose();
  }

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
    final filteredRecipes = pbp.allRecipes
        .where((r) => r.name.toUpperCase().contains(_searchFor.toUpperCase()))
        .toList();
    page = SelPage.articleList; // reuse for highlighting

    return Scaffold(
      appBar: SlappAppBar(title: i18n(context).p_recipes_title),
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
                          flex: 5,
                          child: TextField(
                            decoration: InputDecoration(labelText: i18n(context).com_search_term),
                            onChanged: (text) {
                              _delayedSearch?.cancel();
                              _delayedSearch = Timer(const Duration(milliseconds: 750), () {
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
                          child: Text(i18n(context).com_num_recipes(filteredRecipes.length)),
                        ),
                      ],
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(height: 50, width: 50, child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            itemBuilder: (ctx, idx) {
                              final rec = filteredRecipes[idx];
                              final count = pbp.recipeArticleCount[rec.id] ?? 0;
                              return RecipeCard(
                                recipe: rec,
                                articleCount: count,
                                onTap: () {
                                  Navigator.pushNamed(context, RecipeEditPage.routeName, arguments: rec);
                                },
                              );
                            },
                            itemCount: filteredRecipes.length,
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
          Navigator.pushNamed(context, RecipeEditPage.routeName, arguments: Recipe());
        },
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        tooltip: i18n(context).p_recipes_tooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
