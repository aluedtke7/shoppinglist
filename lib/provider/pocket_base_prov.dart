import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/provider/fetch_dummy.dart'
    if (dart.library.html) 'package:shoppinglist/provider/fetch_stub.dart';
import 'package:vibration/vibration.dart' as vib;

class PocketBaseProvider extends ChangeNotifier {
  PocketBase? _pb;
  final shoppingListCollection = 'shoppinglist';
  final recipesCollection = 'recipes';
  final recipeArticlesCollection = 'recipe_articles';
  List<Article> _active = [];
  List<Article> _allArticles = [];
  List<Article> _searchArticles = [];
  List<Recipe> _allRecipes = [];
  Map<String, int> _recipeArticleCount = {};
  Timer? _healthCheckTimer;
  bool _lastHealthy = true;
  bool _healthy = true;
  String _userName = '';

  bool get isAuth {
    return (_pb?.authStore.isValid ?? false) && (_pb?.authStore.token.isNotEmpty ?? false);
  }

  bool get isHealthy => _healthy;

  String get userName => _userName;

  List<Article> get activeArticles => _active;

  List<Article> get allArticles => _allArticles;

  List<Article> get searchArticles => _searchArticles;

  List<Recipe> get allRecipes => _allRecipes;

  Map<String, int> get recipeArticleCount => _recipeArticleCount;

  Future<void> login(String email, String password) async {
    await ensurePocketBaseIsLoaded();
    ensureKeepAlive();
    if (_pb == null) {
      return;
    }
    final authData = await _pb!.collection('users').authWithPassword(email, password);
    _healthy = true;
    _userName = authData.record.data['name'].toString();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefKeys.accessTokenPrefsKey, _pb!.authStore.token);
    prefs.setString(PrefKeys.accessNamePrefsKey, _userName);
    notifyListeners();
  }

  Future<void> doHealthCheck() async {
    await ensurePocketBaseIsLoaded();
    _pb?.health.check().then((value) {
      _healthy = true;
    }).onError((error, stackTrace) {
      _healthy = false;
    }).whenComplete(() {
      if (_healthy != _lastHealthy) {
        notifyListeners();
      }
      _lastHealthy = _healthy;
    });
  }

  Future<void> ensureKeepAlive() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      doHealthCheck();
    });
  }

  Future<void> logout() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _pb?.authStore.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(PrefKeys.accessTokenPrefsKey);
    prefs.remove(PrefKeys.accessModelPrefsKey);
    prefs.remove(PrefKeys.accessNamePrefsKey);
  }

  Future<bool> tryAutoLogin() async {
    await ensurePocketBaseIsLoaded();
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(PrefKeys.accessNamePrefsKey) ?? '';
    if (_pb == null) {
      return false;
    }
    _pb!.authStore.save(
        prefs.getString(PrefKeys.accessTokenPrefsKey) ?? '',
        RecordModel({
          'email': prefs.getString(PrefKeys.lastUserPrefsKey) ?? '',
        }));
    if (!_pb!.authStore.isValid) {
      return false;
    }
    ensureKeepAlive();
    notifyListeners();
    return _pb!.authStore.isValid;
  }

  Future<void> fetchActive([bool doReload = false]) async {
    await ensurePocketBaseIsLoaded();
    final result = await _pb?.collection(shoppingListCollection).getList(
          filter: 'active = true',
        );
    if (result != null) {
      List<Article> al = [];
      for (var element in result.items) {
        Article art = Article.fromJson(element.toJson());
        al.add(art);
      }
      _active = al.toList();
      _sortActive(_active);
      notifyListeners();
    }
  }

  Future<void> fetchAllArticles([bool doReload = false]) async {
    await ensurePocketBaseIsLoaded();
    final result = await _pb?.collection(shoppingListCollection).getFullList();
    if (result != null) {
      List<Article> al = [];
      for (var element in result) {
        Article art = Article.fromJson(element.toJson());
        al.add(art);
      }
      _allArticles = al.toList();
      _sortActive(_allArticles);
      notifyListeners();
    }
  }

  // --- Recipes ---
  Future<void> fetchAllRecipes([bool doReload = false]) async {
    await ensurePocketBaseIsLoaded();
    final result = await _pb?.collection(recipesCollection).getFullList(sort: '+name');
    if (result != null) {
      _allRecipes = result.map((e) => Recipe.fromJson(e.toJson())).toList();
      // refresh counts alongside recipes
      await fetchRecipeArticleCounts();
      notifyListeners();
    }
  }

  /// Loads all recipe-article links once and computes counts per recipe.
  Future<void> fetchRecipeArticleCounts() async {
    await ensurePocketBaseIsLoaded();
    final res = await _pb?.collection(recipeArticlesCollection).getFullList();
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
    await ensurePocketBaseIsLoaded();
    if (recipe.id.isEmpty) {
      return _pb!.collection(recipesCollection).create(body: recipe.toMap());
    }
    return _pb!.collection(recipesCollection).update(recipe.id, body: recipe.toMap());
  }

  Future<void> deleteRecipe(String id) async {
    await ensurePocketBaseIsLoaded();
    if (id.isEmpty) return;
    await _pb!.collection(recipesCollection).delete(id);
  }

  Future<List<String>> fetchRecipeArticleIds(String recipeId) async {
    await ensurePocketBaseIsLoaded();
    final res = await _pb?.collection(recipeArticlesCollection).getFullList(
          filter: 'recipe = "$recipeId"',
        );
    if (res == null) return [];
    return res.map((e) => e.data['article'] as String).toList();
  }

  /// Returns a map of articleId -> quantity for the given recipe.
  Future<Map<String, int>> fetchRecipeArticleQuantities(String recipeId) async {
    await ensurePocketBaseIsLoaded();
    final res = await _pb?.collection(recipeArticlesCollection).getFullList(
      filter: 'recipe = "$recipeId"',
    );
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
    await ensurePocketBaseIsLoaded();
    await _pb!.collection(recipeArticlesCollection).create(body: {
      'recipe': recipeId,
      'article': articleId,
      'quantity': quantity,
    });
  }

  Future<void> unlinkArticleFromRecipe(String recipeId, String articleId) async {
    await ensurePocketBaseIsLoaded();
    // Find link records then delete
    final res = await _pb!.collection(recipeArticlesCollection).getList(
          filter: 'recipe = "$recipeId" && article = "$articleId"',
        );
    for (final it in res.items) {
      await _pb!.collection(recipeArticlesCollection).delete(it.id);
    }
  }

  /// Updates quantity for an existing recipe-article link; if it doesn't exist, creates it.
  Future<void> updateRecipeArticleQuantity(String recipeId, String articleId, int quantity) async {
    await ensurePocketBaseIsLoaded();
    final q = quantity.clamp(1, 999);
    final res = await _pb!.collection(recipeArticlesCollection).getList(
      filter: 'recipe = "$recipeId" && article = "$articleId"',
    );
    if (res.items.isEmpty) {
      await _pb!.collection(recipeArticlesCollection).create(body: {
        'recipe': recipeId,
        'article': articleId,
        'quantity': q,
      });
      return;
    }
    for (final it in res.items) {
      await _pb!.collection(recipeArticlesCollection).update(it.id, body: {
        'quantity': q,
      });
    }
  }

  Future<void> selectRecipeSetInCart(String recipeId) async {
    await ensurePocketBaseIsLoaded();
    // Get all article quantities linked to this recipe
    final qtyById = await fetchRecipeArticleQuantities(recipeId);
    if (qtyById.isEmpty) return;
    // For each article, mark as active and set inCart=false; set amount from quantity if not active yet
    for (final id in qtyById.keys) {
      try {
        final rec = await _pb!.collection(shoppingListCollection).getOne(id);
        final art = Article.fromJson(rec.toJson());
        art.inCart = false;
        if (!art.active) {
          art.active = true;
          final q = qtyById[id] ?? 1;
          art.amount = q > 0 ? q : 1;
        }
        await _pb!.collection(shoppingListCollection).update(id, body: _articleToMap(art));
      } catch (e) {
        debugPrint('Failed to set inCart for article $id: $e');
      }
    }
    // Refresh active and all to reflect changes
    await fetchActive(true);
    await fetchAllArticles(true);
  }

  Future<void> searchForArticles(String what, bool showAll) async {
    await ensurePocketBaseIsLoaded();
    var searchString = '';
    if (!showAll) {
      searchString += 'active = false && ';
    }
    searchString += '(article ~ "$what" || shop ~ "$what")';
    final result = await _pb?.collection(shoppingListCollection).getList(filter: searchString, sort: '+article');
    if (result != null) {
      List<Article> al = [];
      for (var element in result.items) {
        Article art = Article.fromJson(element.toJson());
        al.add(art);
      }
      _searchArticles = al.toList();
      _sortActive(_searchArticles);
      notifyListeners();
    }
  }

  void clearSearchList() {
    _searchArticles = [];
    notifyListeners();
  }

  void _sortActive(List<Article> list) {
    list.sort((a, b) {
      if (a.inCart != b.inCart) {
        if (a.inCart) {
          return 1;
        } else {
          return -1;
        }
      }
      int ret = a.shop.compareTo(b.shop);
      if (ret != 0) {
        return ret;
      }
      return a.article.compareTo(b.article);
    });
  }

  Map<String, Object> _articleToMap(Article article) {
    return {
      'shop': article.shop,
      'article': article.article,
      'amount': article.amount,
      'inCart': article.inCart,
      'active': article.active
    };
  }

  Future<RecordModel> updateArticle(Article article) async {
    await ensurePocketBaseIsLoaded();
    if (article.id.isEmpty) {
      return _pb!.collection(shoppingListCollection).create(body: _articleToMap(article));
    }
    return _pb!.collection(shoppingListCollection).update(article.id, body: _articleToMap(article));
  }

  Future<RecordModel> toggleinCart(Article article) async {
    if (article.id.isEmpty) {
      return RecordModel();
    }
    await ensurePocketBaseIsLoaded();
    if (![TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows].contains(defaultTargetPlatform)) {
      try {
        if (await vib.Vibration.hasVibrator()) {
          await vib.Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        debugPrint('Vibration impossible: $e');
      }
    }
    article.inCart = !article.inCart;
    return _pb!.collection(shoppingListCollection).update(article.id, body: _articleToMap(article));
  }

  Future<void> endShopping() async {
    await ensurePocketBaseIsLoaded();
    final inCartItems = _active.where((element) => element.inCart).toList();
    for (var itm in inCartItems) {
      itm.inCart = false;
      itm.active = false;
      updateArticle(itm);
    }
  }

  Future<void> subscribeActive() async {
    await ensurePocketBaseIsLoaded();
    _pb?.collection(shoppingListCollection).subscribe('*', (e) {
      debugPrint(e.action); // create, update, delete
      debugPrint(e.record?.toString()); // the changed record
      Article art = Article.fromJson(e.record?.toJson() ?? {});
      if (e.action == 'create') {
        _active.insert(0, art);
      } else if (e.action == 'delete') {
        _active.removeWhere((element) => element.id == art.id);
      } else {
        if (!art.active) {
          _active.removeWhere((element) => element.id == art.id);
        } else {
          int idx = _active.indexWhere((element) => element.id == art.id);
          if (idx < 0) {
            _active.insert(0, art);
          } else {
            _active[idx] = art;
          }
        }
      }
      _sortActive(_active);
      notifyListeners();
    });
  }

  Future<void> unsubscribeActive() async {
    await ensurePocketBaseIsLoaded();
    return _pb?.collection(shoppingListCollection).unsubscribe();
  }

  Future<void> deleteArticle(String id) async {
    await ensurePocketBaseIsLoaded();
    // First remove any links from recipe_articles referencing this article
    try {
      final links = await _pb!
          .collection(recipeArticlesCollection)
          .getList(filter: 'article = "$id"');
      for (final it in links.items) {
        await _pb!.collection(recipeArticlesCollection).delete(it.id);
      }
    } catch (e) {
      debugPrint('Failed to remove recipe links for deleted article $id: $e');
    }

    // Then delete the article itself
    await _pb?.collection(shoppingListCollection).delete(id);
    // keep local caches in sync so UI updates immediately
    _allArticles.removeWhere((element) => element.id == id);
    _active.removeWhere((element) => element.id == id);
    // refresh recipe article counts after link removals
    await fetchRecipeArticleCounts();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _pb!.collection('users').requestPasswordReset(email);
  }

  void setPocketBaseUrl(String url) {
    // for a local PocketBase installation, the default url is 'http://localhost:8090'
    _pb = PocketBase(
      url,
      httpClientFactory: kIsWeb ? () => getClient() : null,
    );
  }

  Future<bool> ensurePocketBaseIsLoaded() async {
    if (_pb == null) {
      final url = await Statics.getServerUrl();
      if (url.isNotEmpty) {
        setPocketBaseUrl(url);
      }
    }
    return _pb != null;
  }
}
