import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

BoxDecoration getSimplePageDecoration() {
  return BoxDecoration(
    color: const Color.fromARGB(255, 200, 200, 200).withValues(alpha: 0.9),
  );
}

BoxDecoration getGradientPageDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        const Color.fromARGB(255, 230, 230, 230).withValues(alpha: 0.5),
        const Color.fromARGB(255, 152, 152, 152).withValues(alpha: 0.9),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, 1],
    ),
  );
}

Color getSlideBtnBackgroundLight(BuildContext ctx) {
  return Theme.of(ctx).colorScheme.primary.withAlpha(200);
}

Color getSlideBtnForegroundLight(BuildContext ctx) {
  return Theme.of(ctx).colorScheme.onPrimary.withAlpha(200);
}

Color getSlideBtnBackgroundDark(BuildContext ctx) {
  return Theme.of(ctx).colorScheme.secondary.withAlpha(200);
}

Color getSlideBtnForegroundDark(BuildContext ctx) {
  return Theme.of(ctx).colorScheme.onSecondary.withAlpha(200);
}

BoxDecoration getGradientDrawerDecoration(BuildContext ctx) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withValues(alpha: .1),
        ThemeProvider.controllerOf(ctx).theme.data.colorScheme.onSurfaceVariant.withAlpha(100),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0, 1],
    ),
  );
}

BoxDecoration getSimpleDrawerDecoration(BuildContext ctx) {
  return BoxDecoration(
    color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withValues(alpha: .1),
  );
}

BoxDecoration getGradientDrawerHeaderDecoration(BuildContext ctx) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
        ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary.withAlpha(100),
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      stops: const [0, 1],
    ),
  );
}

BoxDecoration getSimpleDrawerHeaderDecoration(BuildContext ctx) {
  return BoxDecoration(
    color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
  );
}
