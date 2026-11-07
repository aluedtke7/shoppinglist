import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/component/custom_themes.dart';
import 'package:shoppinglist/component/slapp_menu_sheet.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations.dart';

/// Logged-in provider that never talks to a PocketBase server.
class FakePocketBaseProvider extends PocketBaseProvider {
  @override
  bool get isAuth => true;

  @override
  bool get isHealthy => true;

  @override
  String get userName => 'Anna';
}

Future<void> _openMenu(WidgetTester tester, Size windowSize) async {
  tester.view.physicalSize = windowSize;
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => showSlappMenu(context), child: const Text('menu')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('menu'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'shoppinglist',
      packageName: 'de.luedtke.shoppinglist',
      version: '1.3.0',
      buildNumber: '3',
      buildSignature: '',
    );
  });

  testWidgets('shows the whole menu in a desktop window without overflowing', (tester) async {
    await _openMenu(tester, const Size(800, 620));

    expect(tester.takeException(), isNull);
    expect(find.text('Abmelden'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Abmelden')).dy, lessThan(620));
  });

  testWidgets('scrolls the menu instead of overflowing in a very small window', (tester) async {
    await _openMenu(tester, const Size(400, 300));

    expect(tester.takeException(), isNull);
  });
}
