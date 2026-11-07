import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppinglist/component/custom_themes.dart';
import 'package:shoppinglist/model/pref_keys.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations.dart';
import 'package:shoppinglist/view/login_page.dart';

/// Logged-out provider that never talks to a PocketBase server.
class FakePocketBaseProvider extends PocketBaseProvider {
  @override
  bool get isAuth => false;

  @override
  bool get isHealthy => true;

  @override
  String get userName => '';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({PrefKeys.serverUrlPrefsKey: 'https://slapp.fly.dev'});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('fits a desktop window wider than the form without overflowing', (tester) async {
    // Wider than the 420 px form, so the subtitle wraps inside the form but not at window width.
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<PocketBaseProvider>.value(
        value: FakePocketBaseProvider(),
        child: MaterialApp(
          theme: customThemes[1].data,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('https://slapp.fly.dev'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
