import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart' as vib;
import 'package:pocketbase/pocketbase.dart';

import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/model/pref_keys.dart';

class PocketBaseProvider extends ChangeNotifier {
  final PocketBase _pb = PocketBase(
    const String.fromEnvironment('SHOPPINGLIST_HOST', defaultValue: 'http://localhost:8090'),
    lang: const String.fromEnvironment('SHOPPINGLIST_LANG', defaultValue: 'en-US'),
  );
  final collectionName = 'shoppinglist';
  List<Article> _active = [];
  List<Article> _allArticles = [];
  List<Article> _searchArticles = [];
  Timer? _healthCheckTimer;
  bool _lastHealthy = true;
  bool _healthy = true;
  String _userName = '';

  bool get isAuth {
    return _pb.authStore.isValid && _pb.authStore.token.isNotEmpty;
  }

  bool get isHealthy => _healthy;

  String get userName => _userName;

  List<Article> get activeArticles => _active;
  List<Article> get allArticles => _allArticles;
  List<Article> get searchArticles => _searchArticles;

  Future<void> login(String email, String password) async {
    ensureKeepAlive();
    final authData = await _pb.collection('users').authWithPassword(email, password);
    _healthy = true;
    _userName = authData.record?.data['name'].toString() ?? "";
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefKeys.accessTokenPrefsKey, _pb.authStore.token);
    prefs.setString(PrefKeys.accessModelPrefsKey, _pb.authStore.model.id ?? '');
    prefs.setString(PrefKeys.accessNamePrefsKey, _userName);
    notifyListeners();
  }

  Future<void> doHealthCheck() async {
    _pb.health.check().then((value) {
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
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      doHealthCheck();
    });
  }

  Future<void> logout() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _pb.authStore.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(PrefKeys.accessTokenPrefsKey);
    prefs.remove(PrefKeys.accessModelPrefsKey);
    prefs.remove(PrefKeys.accessNamePrefsKey);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(PrefKeys.accessNamePrefsKey) ?? '';
    _pb.authStore
        .save(prefs.getString(PrefKeys.accessTokenPrefsKey) ?? '', prefs.getString(PrefKeys.accessModelPrefsKey) ?? '');
    if (!_pb.authStore.isValid) {
      return false;
    }
    ensureKeepAlive();
    notifyListeners();
    return _pb.authStore.isValid;
  }

  Future<void> fetchActive([bool doReload = false]) async {
    final result = await _pb.collection(collectionName).getList(
          filter: 'active = true',
        );
    List<Article> al = [];
    for (var element in result.items) {
      Article art = Article.fromJson(element.toJson());
      al.add(art);
    }
    _active = al.toList();
    _sortActive(_active);
    notifyListeners();
  }

  Future<void> fetchAllArticles([bool doReload = false]) async {
    final result = await _pb.collection(collectionName).getFullList();
    List<Article> al = [];
    for (var element in result) {
      Article art = Article.fromJson(element.toJson());
      al.add(art);
    }
    _allArticles = al.toList();
    _sortActive(_allArticles);
    notifyListeners();
  }

  Future<void> searchForArticles(String what) async {
    final searchString = 'active = false && (article ~ "$what" || shop ~ "$what")';
    final result = await _pb.collection(collectionName).getList(filter: searchString, sort: '+article');
    List<Article> al = [];
    for (var element in result.items) {
      Article art = Article.fromJson(element.toJson());
      al.add(art);
    }
    _searchArticles = al.toList();
    _sortActive(_searchArticles);
    notifyListeners();
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
    if (article.id.isEmpty) {
      return _pb.collection(collectionName).create(body: _articleToMap(article));
    }
    return _pb.collection(collectionName).update(article.id, body: _articleToMap(article));
  }

  Future<RecordModel> toggleinCart(Article article) async {
    if (article.id.isEmpty) {
      return RecordModel();
    }
    if (![TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows].contains(defaultTargetPlatform)) {
      try {
        if (await vib.Vibration.hasVibrator() ?? false) {
          await vib.Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        debugPrint('Vibration impossible: $e');
      }
    }
    article.inCart = !article.inCart;
    return _pb.collection(collectionName).update(article.id, body: _articleToMap(article));
  }

  Future<void> endShopping() async {
    final inCartItems = _active.where((element) => element.inCart).toList();
    for (var itm in inCartItems) {
      itm.inCart = false;
      itm.active = false;
      updateArticle(itm);
    }
  }

  Future<void> subscribeActive() async {
    _pb.collection(collectionName).subscribe("*", (e) {
      debugPrint(e.action); // create, update, delete
      debugPrint(e.record?.toString()); // the changed record
      Article art = Article.fromJson(e.record?.toJson() ?? {});
      if (e.action == "create") {
        _active.insert(0, art);
      } else if (e.action == "delete") {
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
    return _pb.collection(collectionName).unsubscribe();
  }

  Future<void> deleteArticle(String id) async {
    return _pb.collection(collectionName).delete(id);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _pb.collection('users').requestPasswordReset(email);
  }
}
