import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/service/haptics.dart';

const _shoppingListCollection = 'shoppinglist';

class ArticleRepository {
  ArticleRepository({
    required PocketBase? Function() pbSync,
    required Future<bool> Function() ensurePb,
    required VoidCallback onChange,
  })  : _pbSync = pbSync,
        _ensurePb = ensurePb,
        _onChange = onChange;

  final PocketBase? Function() _pbSync;
  final Future<bool> Function() _ensurePb;
  final VoidCallback _onChange;

  List<Article> _active = [];
  List<Article> _allArticles = [];
  List<Article> _searchArticles = [];

  List<Article> get active => _active;
  List<Article> get all => _allArticles;
  List<Article> get search => _searchArticles;

  Future<void> fetchActive([bool doReload = false]) async {
    await _ensurePb();
    final result = await _pbSync()?.collection(_shoppingListCollection).getList(
          filter: 'active = true',
        );
    if (result != null) {
      _active = result.items.map((e) => Article.fromJson(e.toJson())).toList();
      _sortActive(_active);
      _onChange();
    }
  }

  Future<void> fetchAllArticles([bool doReload = false]) async {
    await _ensurePb();
    final result = await _pbSync()?.collection(_shoppingListCollection).getFullList();
    if (result != null) {
      _allArticles = result.map((e) => Article.fromJson(e.toJson())).toList();
      _sortActive(_allArticles);
      _onChange();
    }
  }

  Future<void> searchForArticles(String what, bool showAll) async {
    await _ensurePb();
    var searchString = '';
    if (!showAll) {
      searchString += 'active = false && ';
    }
    searchString += '(article ~ "$what" || shop ~ "$what")';
    final result =
        await _pbSync()?.collection(_shoppingListCollection).getList(filter: searchString, sort: '+article');
    if (result != null) {
      _searchArticles = result.items.map((e) => Article.fromJson(e.toJson())).toList();
      _sortActive(_searchArticles);
      _onChange();
    }
  }

  void clearSearchList() {
    _searchArticles = [];
    _onChange();
  }

  Future<RecordModel> updateArticle(Article article) async {
    await _ensurePb();
    final pb = _pbSync()!;
    if (article.id.isEmpty) {
      return pb.collection(_shoppingListCollection).create(body: article.toJson());
    }
    return pb.collection(_shoppingListCollection).update(article.id, body: article.toJson());
  }

  Future<RecordModel> toggleinCart(Article article) async {
    if (article.id.isEmpty) {
      return RecordModel();
    }
    await _ensurePb();
    await vibrateShort();
    final updatedArticle = article.copyWith(inCart: !article.inCart);
    return _pbSync()!.collection(_shoppingListCollection).update(article.id, body: updatedArticle.toJson());
  }

  Future<void> endShopping() async {
    await _ensurePb();
    final inCartItems = _active.where((element) => element.inCart).toList();
    for (var itm in inCartItems) {
      final updatedItm = itm.copyWith(inCart: false, active: false);
      updateArticle(updatedItm);
    }
  }

  /// Marks each article (by id) as active and not in cart, taking the amount from
  /// `qtyById` if the article wasn't already active. Used when adding a recipe to
  /// the active shopping list.
  Future<void> setInCartFromQuantities(Map<String, int> qtyById) async {
    await _ensurePb();
    final pb = _pbSync()!;
    for (final id in qtyById.keys) {
      try {
        final rec = await pb.collection(_shoppingListCollection).getOne(id);
        var art = Article.fromJson(rec.toJson());
        var newAmount = art.amount;
        var newActive = art.active;

        if (!art.active) {
          newActive = true;
          final q = qtyById[id] ?? 1;
          newAmount = q > 0 ? q : 1;
        }

        art = art.copyWith(inCart: false, active: newActive, amount: newAmount);
        await pb.collection(_shoppingListCollection).update(id, body: art.toJson());
      } catch (e) {
        debugPrint('Failed to set inCart for article $id: $e');
      }
    }
  }

  /// Deletes the article record itself and removes it from local caches.
  /// Cross-domain cleanup (recipe-article links) is the orchestrator's job.
  Future<void> deleteArticleOnly(String id) async {
    await _ensurePb();
    await _pbSync()?.collection(_shoppingListCollection).delete(id);
    _allArticles.removeWhere((element) => element.id == id);
    _active.removeWhere((element) => element.id == id);
  }

  Future<void> subscribeActive() async {
    await _ensurePb();
    _pbSync()?.collection(_shoppingListCollection).subscribe('*', (e) {
      debugPrint(e.action);
      debugPrint(e.record?.toString());
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
      _onChange();
    });
  }

  Future<void> unsubscribeActive() async {
    await _ensurePb();
    return _pbSync()?.collection(_shoppingListCollection).unsubscribe();
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
}
