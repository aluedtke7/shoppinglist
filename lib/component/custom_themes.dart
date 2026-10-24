import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

const _fontFamily = 'PlusJakartaSans';

var customThemes = [
  _appTheme('light-blue', 'Light blue', _lightPalette, const Color(0xFF1F5FA8), const Color(0xFFE5EEF8)),
  _appTheme('light-green', 'Light green', _lightPalette, const Color(0xFF157A4A), const Color(0xFFE4F3EA)),
  _appTheme('orange', 'Orange', _lightPalette, const Color(0xFFB04A12), const Color(0xFFFBEBDD)),
  _appTheme('light-orange', 'Light orange', _lightPalette, const Color(0xFFA35F00), const Color(0xFFFDF0DC)),
  _appTheme('dark-cyan', 'Dark cyan', _darkPalette, const Color(0xFF5CC8D6), const Color(0xFF173A40)),
  _appTheme('dark-orange', 'Dark orange', _darkPalette, const Color(0xFFF59E5B), const Color(0xFF3D2614)),
];

/// The neutral colors a theme is built on; the accent comes on top.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.ground,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.outline,
    required this.inCart,
    required this.onAccent,
    required this.danger,
    required this.dangerTint,
  });

  final Brightness brightness;
  final Color ground;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final Color outline;
  final Color inCart;
  final Color onAccent;
  final Color danger;
  final Color dangerTint;
}

const _lightPalette = _Palette(
  brightness: Brightness.light,
  ground: Color(0xFFF5F7F4),
  card: Color(0xFFFFFFFF),
  ink: Color(0xFF14201A),
  muted: Color(0xFF5B6B62),
  line: Color(0xFFE3E8E4),
  outline: Color(0xFFDCE3DE),
  inCart: Color(0xFFEBEFEC),
  onAccent: Color(0xFFFFFFFF),
  danger: Color(0xFFB42318),
  dangerTint: Color(0xFFFCE9E7),
);

const _darkPalette = _Palette(
  brightness: Brightness.dark,
  ground: Color(0xFF101714),
  card: Color(0xFF1A2420),
  ink: Color(0xFFE8EEEA),
  muted: Color(0xFFA3B1A9),
  line: Color(0xFF26322D),
  outline: Color(0xFF34423C),
  inCart: Color(0xFF222D28),
  onAccent: Color(0xFF0B1A14),
  danger: Color(0xFFF2877C),
  dangerTint: Color(0xFF3D1C19),
);

AppTheme _appTheme(String id, String description, _Palette p, Color accent, Color tint) {
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: p.brightness).copyWith(
    primary: accent,
    onPrimary: p.onAccent,
    primaryContainer: tint,
    onPrimaryContainer: accent,
    surface: p.ground,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    surfaceContainerHighest: p.inCart,
    outline: p.outline,
    outlineVariant: p.line,
    error: p.danger,
    errorContainer: p.dangerTint,
    onErrorContainer: p.danger,
    inverseSurface: p.ink,
    onInverseSurface: p.ground,
  );
  final radius16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const buttonText = TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700);
  OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  return AppTheme(
    id: id,
    description: description,
    data: ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: p.ground,
      appBarTheme: AppBarTheme(
        backgroundColor: p.ground,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: radius16,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: inputBorder(p.outline),
        enabledBorder: inputBorder(p.outline),
        focusedBorder: inputBorder(accent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: radius16,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.card,
          foregroundColor: p.ink,
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: radius16,
          side: BorderSide(color: p.outline, width: 1.5),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: p.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: tint,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? accent : p.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? accent : p.muted),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: p.line),
    ),
  );
}
