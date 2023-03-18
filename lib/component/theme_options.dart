import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

typedef ThemedBoxDecoration = BoxDecoration Function(BuildContext context);
typedef ColorGetter = Color Function(BuildContext context);

class ThemeOptions implements AppThemeOptions {
  final Color inCartBackgroundColor;
  final ColorGetter slideBtnBackgroundColor;
  final double cardTextScaleFactor;
  final FontWeight cardTextFontWeight;
  final BoxDecoration pageDecoration;
  final ThemedBoxDecoration drawerDecoration;
  final ThemedBoxDecoration drawerHeaderDecoration;

  ThemeOptions(
    this.inCartBackgroundColor,
    this.slideBtnBackgroundColor,
    this.cardTextScaleFactor,
    this.cardTextFontWeight,
    this.pageDecoration,
    this.drawerDecoration,
    this.drawerHeaderDecoration,
  );
}
