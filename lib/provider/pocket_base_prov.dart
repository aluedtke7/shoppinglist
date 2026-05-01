import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/recipe.dart';
import 'package:shoppinglist/provider/fetch_dummy.dart'
    if (dart.library.html) 'package:shoppinglist/provider/fetch_stub.dart';
import 'package:shoppinglist/service/article_repository.dart';
import 'package:shoppinglist/service/auth_service.dart';
import 'package:shoppinglist/service/config_service.dart';
import 'package:shoppinglist/service/recipe_repository.dart';

class PocketBaseProvider extends ChangeNotifier {
  PocketBase? _pb;

  late final AuthService _auth = AuthService(
    pbSync: () => _pb,
    ensurePb: ensurePocketBaseIsLoaded,
    onChange: notifyListeners,
  );
  late final ArticleRepository _articles = ArticleRepository(
    pbSync: () => _pb,
    ensurePb: ensurePocketBaseIsLoaded,
    onChange: notifyListeners,
  );
  late final RecipeRepository _recipes = RecipeRepository(
    pbSync: () => _pb,
    ensurePb: ensurePocketBaseIsLoaded,
    onChange: notifyListeners,
  );

  // --- Auth ---
  bool get isAuth => _auth.isAuth;
  bool get isHealthy => _auth.isHealthy;
  String get userName => _auth.userName;

  Future<void> login(String email, String password) => _auth.login(email, password);
  Future<void> doHealthCheck() => _auth.doHealthCheck();
  Future<void> ensureKeepAlive() => _auth.ensureKeepAlive();
  Future<void> logout() => _auth.logout();
  Future<bool> tryAutoLogin() => _auth.tryAutoLogin();
  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email);

  // --- Articles ---
  List<Article> get activeArticles => _articles.active;
  List<Article> get allArticles => _articles.all;
  List<Article> get searchArticles => _articles.search;

  Future<void> fetchActive([bool doReload = false]) => _articles.fetchActive(doReload);
  Future<void> fetchAllArticles([bool doReload = false]) => _articles.fetchAllArticles(doReload);
  Future<void> searchForArticles(String what, bool showAll) => _articles.searchForArticles(what, showAll);
  void clearSearchList() => _articles.clearSearchList();
  Future<RecordModel> updateArticle(Article article) => _articles.updateArticle(article);
  Future<RecordModel> toggleinCart(Article article) => _articles.toggleinCart(article);
  Future<void> endShopping() => _articles.endShopping();
  Future<void> subscribeActive() => _articles.subscribeActive();
  Future<void> unsubscribeActive() => _articles.unsubscribeActive();

  // --- Recipes ---
  List<Recipe> get allRecipes => _recipes.all;
  Map<String, int> get recipeArticleCount => _recipes.articleCount;

  Future<void> fetchAllRecipes([bool doReload = false]) => _recipes.fetchAllRecipes(doReload);
  Future<void> fetchRecipeArticleCounts() => _recipes.fetchRecipeArticleCounts();
  Future<RecordModel> updateRecipe(Recipe recipe) => _recipes.updateRecipe(recipe);
  Future<void> deleteRecipe(String id) => _recipes.deleteRecipe(id);
  Future<List<String>> fetchRecipeArticleIds(String recipeId) => _recipes.fetchRecipeArticleIds(recipeId);
  Future<Map<String, int>> fetchRecipeArticleQuantities(String recipeId) =>
      _recipes.fetchRecipeArticleQuantities(recipeId);
  Future<void> linkArticleToRecipe(String recipeId, String articleId, {int quantity = 1}) =>
      _recipes.linkArticleToRecipe(recipeId, articleId, quantity: quantity);
  Future<void> unlinkArticleFromRecipe(String recipeId, String articleId) =>
      _recipes.unlinkArticleFromRecipe(recipeId, articleId);
  Future<void> updateRecipeArticleQuantity(String recipeId, String articleId, int quantity) =>
      _recipes.updateRecipeArticleQuantity(recipeId, articleId, quantity);

  // --- Cross-domain orchestration ---
  Future<void> selectRecipeSetInCart(String recipeId) async {
    final qtyById = await _recipes.fetchRecipeArticleQuantities(recipeId);
    if (qtyById.isEmpty) return;
    await _articles.setInCartFromQuantities(qtyById);
    await _articles.fetchActive(true);
    await _articles.fetchAllArticles(true);
  }

  Future<void> deleteArticle(String id) async {
    await _recipes.removeLinksForArticle(id);
    await _articles.deleteArticleOnly(id);
    await _recipes.fetchRecipeArticleCounts();
    notifyListeners();
  }

  // --- Connection ---
  void setPocketBaseUrl(String url) {
    // for a local PocketBase installation, the default url is 'http://localhost:8090'
    _pb = PocketBase(
      url,
      httpClientFactory: kIsWeb ? () => getClient() : null,
    );
  }

  Future<bool> ensurePocketBaseIsLoaded() async {
    if (_pb == null) {
      final url = await getServerUrl();
      if (url.isNotEmpty) {
        setPocketBaseUrl(url);
      }
    }
    return _pb != null;
  }
}
