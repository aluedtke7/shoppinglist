import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';

var customThemes = [
  AppTheme(
    id: 'light-blue',
    description: 'Light blue',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.lightBlue,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      Statics.getSlideBtnForegroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-green',
    description: 'Light green',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.lightGreen,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      Statics.getSlideBtnForegroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'orange',
    description: 'Orange',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        primary: Colors.orange,
        seedColor: Colors.orange,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      Statics.getSlideBtnForegroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-orange',
    description: 'Light orange',
    data: ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(
        seedColor:  Colors.orange,
        primary: Colors.orange,
        brightness: Brightness.light,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      Statics.getSlideBtnForegroundLight,
      1.1,
      FontWeight.normal,
      Statics.getSimplePageDecoration(),
      Statics.getSimpleDrawerDecoration,
      Statics.getSimpleDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark-cyan',
    description: 'Dark cyan',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: Colors.cyan,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 50, 50, 50)),
    ),
    options: ThemeOptions(
      Colors.grey.shade600,
      Statics.getSlideBtnBackgroundDark,
      Statics.getSlideBtnForegroundDark,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark-orange',
    description: 'Dark orange',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: Colors.orange,
      ),
    ),
    options: ThemeOptions(
      Colors.grey.shade600,
      Statics.getSlideBtnBackgroundDark,
      Statics.getSlideBtnForegroundDark,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
];
