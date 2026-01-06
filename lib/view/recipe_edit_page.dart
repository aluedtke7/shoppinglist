import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:shoppinglist/component/theme_options.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/slapp_app_bar.dart';
import 'package:shoppinglist/component/slapp_drawer.dart';
import 'package:shoppinglist/component/recipe_selected_article_card.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/component/no_article_widget.dart';

class RecipeEditPage extends StatefulWidget {
  const RecipeEditPage({super.key});

  static const routeName = '/recipe_edit';

  @override
  State<RecipeEditPage> createState() => _RecipeEditPageState();
}

class _RecipeEditPageState extends State<RecipeEditPage> {
  final _formKey = GlobalKey<FormState>();
  late Recipe _recipe;
  bool _loading = true;

  // Selected articleId -> quantity
  final Map<String, int> _selectedArticles = {};
  late final TextEditingController _nameCtl;
  late final TextEditingController _notesCtl;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final arg = ModalRoute.of(context)!.settings.arguments;
    _recipe = (arg is Recipe) ? Recipe(id: arg.id, name: arg.name, notes: arg.notes) : Recipe();
    _nameCtl = TextEditingController(text: _recipe.name);
    _notesCtl = TextEditingController(text: _recipe.notes);
    _loadData();
  }

  @override
  void dispose() {
    if (mounted) {
      _nameCtl.dispose();
      _notesCtl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final pbp = context.read<PocketBaseProvider>();
    await pbp.fetchAllArticles();
    _selectedArticles.clear();
    if (_recipe.id.isNotEmpty) {
      final qtyMap = await pbp.fetchRecipeArticleQuantities(_recipe.id);
      _selectedArticles.addAll(qtyMap);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pbp = context.read<PocketBaseProvider>();
    // Capture navigator before any awaits to avoid using BuildContext across async gaps
    final navigator = Navigator.of(context);
    // take latest values from controllers
    _recipe.name = _nameCtl.text.trim();
    _recipe.notes = _notesCtl.text.trim();
    // save/ensure recipe exists
    final rec = await pbp.updateRecipe(_recipe);
    final recipeId = rec.id;
    // compute changes with quantities
    final currentQty = await pbp.fetchRecipeArticleQuantities(recipeId);
    final wantIds = _selectedArticles.keys.toList();
    final currentIds = currentQty.keys.toList();
    final toAdd = wantIds.where((id) => !currentIds.contains(id));
    final toRemove = currentIds.where((id) => !wantIds.contains(id));
    for (final id in toAdd) {
      await pbp.linkArticleToRecipe(recipeId, id, quantity: _selectedArticles[id] ?? 1);
    }
    for (final id in toRemove) {
      await pbp.unlinkArticleFromRecipe(recipeId, id);
    }
    // update changed quantities
    for (final id in wantIds) {
      final newQty = (_selectedArticles[id] ?? 1).clamp(1, 999);
      final oldQty = currentQty[id];
      if (oldQty != null && oldQty != newQty) {
        await pbp.updateRecipeArticleQuantity(recipeId, id, newQty);
      }
    }
    // Refresh recipes so the list updates when returning
    await pbp.fetchAllRecipes();
    if (!context.mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pbp = context.watch<PocketBaseProvider>();
    return Scaffold(
      appBar: SlappAppBar(title: _recipe.id == '' ? i18n(context).p_recipe_new : i18n(context).p_recipe_change),
      drawer: const SlappDrawer(),
      body: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtl,
                          autofocus: _recipe.id == '',
                          decoration: InputDecoration(labelText: i18n(context).p_recipe_name),
                          validator: (v) => (v == null || v.trim().isEmpty) ? i18n(context).com_required : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesCtl,
                          decoration: InputDecoration(labelText: i18n(context).p_recipe_notes),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                pbp.clearSearchList();
                                final Article? found =
                                    await Statics.searchForArticle(context, pbp, dontAdd: true, showAll: true);
                                if (found != null) {
                                  setState(() {
                                    // add with default quantity 1; prevent duplicates
                                    _selectedArticles.putIfAbsent(found.id, () => 1);
                                  });
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text(i18n(context).p_article_add),
                            ),
                            const SizedBox(width: 12),
                            Text(i18n(context).com_num_articles(_selectedArticles.length))
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _selectedArticles.isEmpty
                              ? const NoArticleWidget(height: 1.2)
                              : ListView(
                                  children: _selectedArticles.keys
                                      .map((id) => pbp.allArticles.firstWhere(
                                            (a) => a.id == id,
                                            orElse: () => Article(id: id, article: i18n(context).com_unknown, shop: ''),
                                          ))
                                      .map((a) {
                                    final qty = _selectedArticles[a.id] ?? 1;
                                    return RecipeSelectedArticleCard(
                                      article: a,
                                      quantity: qty,
                                      onDecrease: () {
                                        setState(() {
                                          final v = (_selectedArticles[a.id] ?? 1) - 1;
                                          _selectedArticles[a.id] = v < 1 ? 1 : v;
                                        });
                                      },
                                      onIncrease: () {
                                        setState(() {
                                          final v = (_selectedArticles[a.id] ?? 1) + 1;
                                          _selectedArticles[a.id] = v > 100 ? 100 : v;
                                        });
                                      },
                                      onRemove: () {
                                        setState(() {
                                          _selectedArticles.remove(a.id);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_recipe.id.isNotEmpty)
                              OutlinedButton(
                                onPressed: () async {
                                  final bool? sure = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(i18n(context).p_recipe_delete),
                                      content: Text(i18n(context).p_recipe_delete_confirm),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: Text(i18n(context).com_cancel),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: Text(i18n(context).com_delete),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (sure == true) {
                                    try {
                                      // remove links first (best effort)
                                      final ids = await pbp.fetchRecipeArticleIds(_recipe.id);
                                      for (final id in ids) {
                                        await pbp.unlinkArticleFromRecipe(_recipe.id, id);
                                      }
                                      await pbp.deleteRecipe(_recipe.id);
                                      await pbp.fetchAllRecipes();
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      if (context.mounted) {
                                        Statics.showErrorSnackbar(context, 'Failed to delete: $e');
                                      }
                                    }
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: Text(i18n(context).com_delete),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(i18n(context).com_cancel),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _save,
                                  child: Text(i18n(context).com_save),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
