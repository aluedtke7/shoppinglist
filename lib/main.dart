import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/application.dart';
import 'package:shoppinglist/component/custom_themes.dart';
import 'package:shoppinglist/provider/pocket_base_prov.dart';
import 'package:shoppinglist/specific_localization_delegate.dart';
import 'package:shoppinglist/view/active_page.dart';
import 'package:shoppinglist/view/article_edit_page.dart';
import 'package:shoppinglist/view/article_page.dart';
import 'package:shoppinglist/view/login_page.dart';
import 'package:shoppinglist/view/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PocketBaseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SpecificLocalizationDelegate _localeOverrideDelegate;

  @override
  void initState() {
    super.initState();
    final String initialLanguage;
    if (kIsWeb) {
      initialLanguage = PlatformDispatcher.instance.locale.languageCode;
    } else {
      initialLanguage = Platform.localeName.substring(0, 2);
    }
    _localeOverrideDelegate = SpecificLocalizationDelegate(Locale(initialLanguage));
    Intl.defaultLocale = initialLanguage;
    APPLIC().onLocaleChanged = onLocaleChange;
  }

  void onLocaleChange(Locale locale) {
    setState(() {
      debugPrint('onLocaleChange: ${locale.languageCode}');
      _localeOverrideDelegate = SpecificLocalizationDelegate(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      onThemeChanged: (oldTheme, newTheme) {
        debugPrint('Theme: ${newTheme.id}');
      },
      loadThemeOnInit: true,
      saveThemesOnChange: true,
      themes: customThemes,
      child: ThemeConsumer(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: PocketBaseProvider(),
            ),
          ],
          child: Consumer<PocketBaseProvider>(
            builder: (context, pbp, _) => MaterialApp(
              title: 'Shoppinglist',
              theme: ThemeProvider.themeOf(context).data,
              localizationsDelegates: [
                _localeOverrideDelegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: APPLIC().supportedLocales(),
              home: pbp.isAuth
                  ? const ActivePage()
                  : FutureBuilder(
                      future: pbp.tryAutoLogin(),
                      builder: (context, snapshot) => snapshot.connectionState == ConnectionState.waiting
                          ? const SplashScreen()
                          : const LoginPage(),
                    ),
              routes: {
                // LoginPage.routeName: (context) => const LoginPage(),
                // --- Views/Pages ---
                ActivePage.routeName: (context) => const ActivePage(),
                ArticlePage.routeName: (context) => const ArticlePage(),
                // --- Edits ---
                ArticleEditPage.routeName: (context) => const ArticleEditPage(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
