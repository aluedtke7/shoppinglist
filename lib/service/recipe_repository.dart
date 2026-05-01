import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:shoppinglist/model/recipe.dart';

const _recipesCollection = 'recipes';
const _recipeArticlesCollection = 'recipe_articles';

class RecipeRepository {
  RecipeRepository({
    required PocketBase? Function() pbSync,
    required Future<bool> Function() ensurePb,
    required VoidCallback onChange,
  })  : _pbSync = pbSync,
        _ensurePb = ensurePb,
        _onChange = onChange;

  final PocketBase? Function() _pbSync;
  final Future<bool> Function() _ensurePb;
  final VoidCallback _onChange;

  List<Recipe> _allRecipes = [];
  Map<String, int> _recipeArticleCount = {};

  List<Recipe> get all => _allRecipes;
  Map<String, int> get articleCount => _recipeArticleCount;

  Future<void> fetchAllRecipes([bool doReload = false]) async {
    await _ensurePb();
    final result = await _pbSync()?.collection(_recipesCollection).getFullList(sort: '+name');
    if (result != null) {
      _allRecipes = result.map((e) => Recipe.fromJson(e.toJson())).toList();
      await fetchRecipeArticleCounts();
      _onChange();
    }
  }

  /// Loads all recipe-article links once and computes counts per recipe.
  Future<void> fetchRecipeArticleCounts() async {
    await _ensurePb();
    final res = await _pbSync()?.collection(_recipeArticlesCollection).getFullList();
    final Map<String, int> cnt = {};
    if (res != null) {
      for (final r in res) {
        final rid = (r.data['recipe'] as String?) ?? '';
        if (rid.isEmpty) continue;
        cnt.update(rid, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    _recipeArticleCount = cnt;
    // don't notify here unconditionally; callers will decide, to avoid double rebuilds
  }

  Future<RecordModel> updateRecipe(Recipe recipe) async {
    await _ensurePb();
    final pb = _pbSync()!;
    if (recipe.id.isEmpty) {
      return pb.collection(_recipesCollection).create(body: recipe.toMap());
    }
    return pb.collection(_recipesCollection).update(recipe.id, body: recipe.toMap());
  }

  Future<void> deleteRecipe(String id) async {
    await _ensurePb();
    if (id.isEmpty) return;
    await _pbSync()!.collection(_recipesCollection).delete(id);
  }

  Future<List<String>> fetchRecipeArticleIds(String recipeId) async {
    await _ensurePb();
    final res = await _pbSync()?.collection(_recipeArticlesCollection).getFullList(
          filter: 'recipe = "$recipeId"',
        );
    if (res == null) return [];
    return res.map((e) => e.data['article'] as String).toList();
  }

  /// Returns a map of articleId -> quantity for the given recipe.
  Future<Map<String, int>> fetchRecipeArticleQuantities(String recipeId) async {
    await _ensurePb();
    final res =
        await _pbSync()?.collection(_recipeArticlesCollection).getFullList(filter: 'recipe = "$recipeId"');
    if (res == null) return {};
    final Map<String, int> out = {};
    for (final rec in res) {
      final aid = rec.data['article'] as String? ?? '';
      if (aid.isEmpty) continue;
      final q = rec.data['quantity'];
      int qty;
      if (q is num) {
        qty = q.toInt();
      } else if (q is String) {
        qty = int.tryParse(q) ?? 1;
      } else {
        qty = 1;
      }
      out[aid] = qty;
    }
    return out;
  }

  Future<void> linkArticleToRecipe(String recipeId, String articleId, {int quantity = 1}) async {
    await _ensurePb();
    await _pbSync()!.collection(_recipeArticlesCollection).create(body: {
      'recipe': recipeId,
      'article': articleId,
      'quantity': quantity,
    });
  }

  Future<void> unlinkArticleFromRecipe(String recipeId, String articleId) async {
    await _ensurePb();
    final pb = _pbSync()!;
    final res = await pb.collection(_recipeArticlesCollection).getList(
          filter: 'recipe = "$recipeId" && article = "$articleId"',
        );
    for (final it in res.items) {
      await pb.collection(_recipeArticlesCollection).delete(it.id);
    }
  }

  /// Updates quantity for an existing recipe-article link; if it doesn't exist, creates it.
  Future<void> updateRecipeArticleQuantity(String recipeId, String articleId, int quantity) async {
    await _ensurePb();
    final pb = _pbSync()!;
    final q = quantity.clamp(1, 999);
    final res = await pb.collection(_recipeArticlesCollection).getList(
          filter: 'recipe = "$recipeId" && article = "$articleId"',
        );
    if (res.items.isEmpty) {
      await pb.collection(_recipeArticlesCollection).create(body: {
        'recipe': recipeId,
        'article': articleId,
        'quantity': q,
      });
      return;
    }
    for (final it in res.items) {
      await pb.collection(_recipeArticlesCollection).update(it.id, body: {
        'quantity': q,
      });
    }
  }

  /// Removes every recipe-article link that references the given article.
  /// Used when an article is being deleted, so recipe membership stays consistent.
  Future<void> removeLinksForArticle(String articleId) async {
    await _ensurePb();
    final pb = _pbSync()!;
    try {
      final links = await pb.collection(_recipeArticlesCollection).getList(filter: 'article = "$articleId"');
      for (final it in links.items) {
        await pb.collection(_recipeArticlesCollection).delete(it.id);
      }
    } catch (e) {
      debugPrint('Failed to remove recipe links for deleted article $articleId: $e');
    }
  }
}
