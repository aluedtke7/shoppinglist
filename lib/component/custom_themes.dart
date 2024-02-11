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
    id: 'light-green',
    description: 'Light green',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.lightGreen,
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
    id: 'orange',
    description: 'Orange',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.orange,
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.light,
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
    id: 'dark-cyan',
    description: 'Dark cyan',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: Colors.cyan,
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
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
];
