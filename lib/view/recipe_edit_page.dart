import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/component/i18n_util.dart';
import 'package:shoppinglist/component/dialogs.dart';
import 'package:shoppinglist/component/recipe_selected_article_card.dart';
import 'package:shoppinglist/component/snackbars.dart';
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

    // update recipe object with latest values from controllers
    _recipe = _recipe.copyWith(
      name: _nameCtl.text.trim(),
      notes: _notesCtl.text.trim(),
    );

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

  Future<void> _delete() async {
    final sure = await showDeleteConfirmDialog(
      context,
      i18n(context).p_recipe_delete,
      i18n(context).p_recipe_delete_confirm,
    );
    if (sure != true || !mounted) return;
    final pbp = context.read<PocketBaseProvider>();
    try {
      // remove links first (best effort)
      final ids = await pbp.fetchRecipeArticleIds(_recipe.id);
      for (final id in ids) {
        await pbp.unlinkArticleFromRecipe(_recipe.id, id);
      }
      await pbp.deleteRecipe(_recipe.id);
      await pbp.fetchAllRecipes();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to delete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pbp = context.watch<PocketBaseProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe.id == '' ? i18n(context).p_recipe_new : i18n(context).p_recipe_change),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtl,
                        autofocus: _recipe.id == '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(labelText: i18n(context).p_recipe_name),
                        validator: (v) => (v == null || v.trim().isEmpty) ? i18n(context).com_required : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesCtl,
                        decoration: InputDecoration(labelText: i18n(context).p_recipe_notes),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(
                                  i18n(context).com_article,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  i18n(context).com_num_articles(_selectedArticles.length),
                                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              pbp.clearSearchList();
                              final Article? found = await searchForArticle(context, pbp, dontAdd: true, showAll: true);
                              if (found != null) {
                                setState(() {
                                  _selectedArticles.putIfAbsent(found.id, () => 1);
                                });
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.primary,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(i18n(context).p_article_add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _RecipeArticlesList(
                          selectedArticles: _selectedArticles,
                          allArticles: pbp.allArticles,
                          onIncrease: (id) => setState(() {
                            final v = (_selectedArticles[id] ?? 1) + 1;
                            _selectedArticles[id] = v > 100 ? 100 : v;
                          }),
                          onDecrease: (id) => setState(() {
                            final v = (_selectedArticles[id] ?? 1) - 1;
                            _selectedArticles[id] = v < 1 ? 1 : v;
                          }),
                          onRemove: (id) => setState(() {
                            _selectedArticles.remove(id);
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RecipeEditFooter(
                        showDelete: _recipe.id.isNotEmpty,
                        onCancel: () => Navigator.pop(context),
                        onSave: _save,
                        onDelete: _delete,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _RecipeArticlesList extends StatelessWidget {
  const _RecipeArticlesList({
    required this.selectedArticles,
    required this.allArticles,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final Map<String, int> selectedArticles;
  final List<Article> allArticles;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (selectedArticles.isEmpty) {
      return const NoArticleWidget(height: 1.2);
    }
    final unknownLabel = i18n(context).com_unknown;
    final articles = selectedArticles.keys.map(
      (id) => allArticles.firstWhere(
        (a) => a.id == id,
        orElse: () => Article(id: id, article: unknownLabel, shop: ''),
      ),
    );
    return ListView(
      children: articles.map((a) {
        final qty = selectedArticles[a.id] ?? 1;
        return RecipeSelectedArticleCard(
          article: a,
          quantity: qty,
          onDecrease: () => onDecrease(a.id),
          onIncrease: () => onIncrease(a.id),
          onRemove: () => onRemove(a.id),
        );
      }).toList(),
    );
  }
}

class _RecipeEditFooter extends StatelessWidget {
  const _RecipeEditFooter({
    required this.showDelete,
    required this.onCancel,
    required this.onSave,
    required this.onDelete,
  });

  final bool showDelete;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Three buttons share one row, so they need less horizontal padding than the theme default.
    const padding = EdgeInsets.symmetric(horizontal: 12);

    return Row(
      spacing: 10,
      children: [
        if (showDelete)
          FilledButton(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.error,
              minimumSize: const Size(0, 56),
              padding: padding,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(i18n(context).com_delete),
          ),
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(padding: padding),
            child: Text(i18n(context).com_cancel),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(padding: padding),
            child: Text(i18n(context).com_save),
          ),
        ),
      ],
    );
  }
}
