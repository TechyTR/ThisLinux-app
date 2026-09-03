import 'package:flutter/material.dart';

enum AppThemeColor { purple, blue, green, orange }

enum AppThemeStyle { normal, liquidGlassLight, liquidGlassDark }

extension AppThemeColorExtension on AppThemeColor {
  Color get seed {
    switch (this) {
      case AppThemeColor.purple:
        return const Color(0xFF8E7CC3);
      case AppThemeColor.blue:
        return const Color(0xFF5B8DEF);
      case AppThemeColor.green:
        return const Color(0xFF6FAE7A);
      case AppThemeColor.orange:
        return const Color(0xFFE0A972);
    }
  }

  String get label {
    switch (this) {
      case AppThemeColor.purple:
        return 'Mor';
      case AppThemeColor.blue:
        return 'Mavi';
      case AppThemeColor.green:
        return 'Yeşil';
      case AppThemeColor.orange:
        return 'Turuncu';
    }
  }
}

class AppTheme {
  static ThemeData build(AppThemeColor color, AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.normal:
        return _normal(color);
      case AppThemeStyle.liquidGlassLight:
        return _liquidGlassLight(color);
      case AppThemeStyle.liquidGlassDark:
        return _liquidGlassDark(color);
    }
  }

  static ThemeData _normal(AppThemeColor color) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101010),
      appBarTheme: const AppBarTheme(elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData _liquidGlassLight(AppThemeColor color) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F3F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.38),
        surfaceTintColor: Colors.white.withOpacity(0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.52)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withOpacity(0.86),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.32),
        thickness: 0.7,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.48)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.42)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: color.seed.withOpacity(0.55), width: 1.3),
        ),
      ),
    );
  }

  static ThemeData _liquidGlassDark(AppThemeColor color) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF08090D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.065),
        surfaceTintColor: Colors.white.withOpacity(0.025),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.17)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF15171D).withOpacity(0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.12),
        thickness: 0.7,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.055),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.13)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: color.seed.withOpacity(0.50), width: 1.3),
        ),
      ),
    );
  }

  static AppThemeColor colorFromString(String value) => AppThemeColor.values.firstWhere(
        (item) => item.name == value,
        orElse: () => AppThemeColor.purple,
      );

  static String colorToString(AppThemeColor color) => color.name;

  static AppThemeStyle styleFromString(String value) => AppThemeStyle.values.firstWhere(
        (item) => item.name == value,
        orElse: () => AppThemeStyle.normal,
      );

  static String styleToString(AppThemeStyle style) => style.name;
  static Color colorOf(AppThemeColor color) => color.seed;
  static String labelOf(AppThemeColor color) => color.label;

  static String styleLabelOf(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.normal:
        return 'Material Design';
      case AppThemeStyle.liquidGlassLight:
        return 'Liquid Glass Light';
      case AppThemeStyle.liquidGlassDark:
        return 'Liquid Glass Dark';
    }
  }
}
