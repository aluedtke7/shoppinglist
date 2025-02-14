import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations_de.dart';
import 'package:shoppinglist/src/generated/i18n/app_localizations_en.dart';

class SpecificLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  final Locale overriddenLocale;

  const SpecificLocalizationDelegate(this.overriddenLocale);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Lookup logic when only language code is specified.
    switch (overriddenLocale.languageCode) {
      case 'de':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsDe());
      case 'en':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
    }
    // if language can't be found, use English as default
    return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => true;
}
