import 'package:shared_preferences/shared_preferences.dart';

import 'package:shoppinglist/model/pref_keys.dart';

Future<String> getServerUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final debugUrl = const String.fromEnvironment('SHOPPINGLIST_HOST', defaultValue: '');
  return debugUrl.isNotEmpty ? debugUrl : prefs.getString(PrefKeys.serverUrlPrefsKey) ?? '';
}
