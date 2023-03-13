import 'dart:ui';

import 'package:flutter/widgets.dart';

typedef LocaleChangeCallback = void Function(Locale locale);

class APPLIC {
  // List of supported languages
  final List<String> supportedLanguages = ['en', 'de'];

  // Returns the list of supported Locales
  Iterable<Locale> supportedLocales() => supportedLanguages.map<Locale>((lang) => Locale(lang, ''));

  // Function to be invoked when changing the working language
  late LocaleChangeCallback onLocaleChanged;

  ///
  /// Internals
  ///
  static final APPLIC _applic = APPLIC._internal();

  factory APPLIC() {
    return _applic;
  }

  APPLIC._internal();
}
