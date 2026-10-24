import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shoppinglist/component/custom_themes.dart';
import 'package:shoppinglist/model/article.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations.dart';
import 'package:shoppinglist/view/active_page.dart';

/// Serves a fixed shopping list without a PocketBase server.
class FakePocketBaseProvider extends PocketBaseProvider {
  FakePocketBaseProvider(this.articles);

  final List<Article> articles;
  final toggled = <Article>[];

  @override
  bool get isAuth => true;

  @override
  bool get isHealthy => true;

  @override
  String get userName => 'anna';

  @override
  List<Article> get activeArticles => articles;

  @override
  Future<void> subscribeActive() async {}

  @override
  Future<void> unsubscribeActive() async {}

  @override
  Future<void> fetchActive([bool doReload = false]) async {}

  @override
  Future<void> fetchAllRecipes([bool doReload = false]) async {}

  @override
  Future<RecordModel> toggleinCart(Article article) async {
    toggled.add(article);
    return RecordModel();
  }
}

Widget _app(PocketBaseProvider pbp) {
  return ChangeNotifierProvider<PocketBaseProvider>.value(
    value: pbp,
    child: MaterialApp(
      theme: customThemes[1].data,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ActivePage(),
    ),
  );
}

void main() {
  const milk = Article(id: '1', shop: 'Edeka', article: 'Milch', amount: 2, active: true);
  const toothpaste = Article(id: '2', shop: 'dm', article: 'Zahnpasta', amount: 1, active: true);
  const cheese = Article(id: '3', shop: 'Edeka', article: 'Käse', amount: 1, active: true, inCart: true);

  testWidgets('shows articles grouped by shop and the cart separately', (tester) async {
    await tester.pumpWidget(_app(FakePocketBaseProvider([toothpaste, milk, cheese])));
    await tester.pumpAndSettle();

    expect(find.text('DM'), findsOneWidget);
    expect(find.text('EDEKA'), findsOneWidget);
    expect(find.text('IM WAGEN'), findsOneWidget);
    expect(find.text('1 von 3 im Wagen'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
  });

  testWidgets('tapping the check circle toggles the article', (tester) async {
    final pbp = FakePocketBaseProvider([milk]);
    await tester.pumpWidget(_app(pbp));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('In den Wagen'));

    expect(pbp.toggled, [milk]);
  });

  testWidgets('double tapping the article name toggles the article', (tester) async {
    final pbp = FakePocketBaseProvider([milk]);
    await tester.pumpWidget(_app(pbp));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milch'));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.text('Milch'));
    await tester.pumpAndSettle();

    expect(pbp.toggled, [milk]);
  });

  testWidgets('shows the empty hint without articles', (tester) async {
    await tester.pumpWidget(_app(FakePocketBaseProvider([])));
    await tester.pumpAndSettle();

    expect(find.textContaining('kein Artikel'), findsOneWidget);
  });
}
