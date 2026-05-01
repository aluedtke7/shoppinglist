import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shoppinglist/model/pref_keys.dart';

class AuthService {
  AuthService({
    required PocketBase? Function() pbSync,
    required Future<bool> Function() ensurePb,
    required VoidCallback onChange,
  })  : _pbSync = pbSync,
        _ensurePb = ensurePb,
        _onChange = onChange;

  final PocketBase? Function() _pbSync;
  final Future<bool> Function() _ensurePb;
  final VoidCallback _onChange;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Timer? _healthCheckTimer;
  bool _lastHealthy = true;
  bool _healthy = true;
  String _userName = '';

  bool get isAuth {
    final pb = _pbSync();
    return (pb?.authStore.isValid ?? false) && (pb?.authStore.token.isNotEmpty ?? false);
  }

  bool get isHealthy => _healthy;

  String get userName => _userName;

  Future<void> login(String email, String password) async {
    await _ensurePb();
    ensureKeepAlive();
    final pb = _pbSync();
    if (pb == null) {
      return;
    }
    final authData = await pb.collection('users').authWithPassword(email, password);
    _healthy = true;
    _userName = authData.record.data['name'].toString();
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: PrefKeys.accessTokenSecureKey, value: pb.authStore.token);
    prefs.setString(PrefKeys.accessNamePrefsKey, _userName);
    _onChange();
  }

  Future<void> doHealthCheck() async {
    await _ensurePb();
    _pbSync()?.health.check().then((value) {
      _healthy = true;
    }).onError((error, stackTrace) {
      _healthy = false;
    }).whenComplete(() {
      if (_healthy != _lastHealthy) {
        _onChange();
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
    _pbSync()?.authStore.clear();
    await _secureStorage.delete(key: PrefKeys.accessTokenSecureKey);
  }

  Future<bool> tryAutoLogin() async {
    await _ensurePb();
    final pb = _pbSync();
    if (pb == null) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    var email = await _secureStorage.read(key: PrefKeys.lastEmailSecureKey) ?? '';
    _userName = prefs.getString(PrefKeys.accessNamePrefsKey) ?? '';
    var token = await _secureStorage.read(key: PrefKeys.accessTokenSecureKey) ?? '';
    pb.authStore.save(
        token,
        RecordModel({
          'email': email,
        }));
    if (!pb.authStore.isValid) {
      return false;
    }
    ensureKeepAlive();
    _onChange();
    return pb.authStore.isValid;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _pbSync()!.collection('users').requestPasswordReset(email);
  }
}
