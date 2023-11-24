import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:shoppinglist/component/statics.dart';
import 'package:shoppinglist/component/theme_options.dart';

var customThemes = [
  AppTheme(
    id: 'light',
    description: 'Light',
    data: ThemeData(
      useMaterial3: false,
      dialogBackgroundColor: const Color.fromARGB(255, 240, 240, 240),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark',
    description: 'Dark',
    data: ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        accentColor: Colors.cyan.shade700,
      ),
      dialogBackgroundColor: const Color.fromARGB(255, 50, 50, 50),
    ),
    options: ThemeOptions(
      Colors.grey.shade600,
      Statics.getSlideBtnBackgroundDark,
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
      useMaterial3: false,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrange.shade700,
      ),
      dialogBackgroundColor: const Color.fromARGB(255, 240, 240, 240),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
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
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrange,
      ),
      dialogBackgroundColor: const Color.fromARGB(255, 240, 240, 240),
    ),
    options: ThemeOptions(
      Colors.grey.shade400,
      Statics.getSlideBtnBackgroundLight,
      1.1,
      FontWeight.normal,
      Statics.getSimplePageDecoration(),
      Statics.getSimpleDrawerDecoration,
      Statics.getSimpleDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark-orange',
    description: 'Dark orange',
    data: ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        accentColor: Colors.orange.shade700,
      ),
    ),
    options: ThemeOptions(
      Colors.grey.shade600,
      Statics.getSlideBtnBackgroundDark,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
];
