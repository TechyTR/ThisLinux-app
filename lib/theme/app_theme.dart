import 'package:flutter/material.dart';

enum AppThemeColor {
  purple,
  blue,
  green,
  orange,
}

extension AppThemeColorSeed on AppThemeColor {
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
  static ThemeData light(AppThemeColor color) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color.seed,
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData dark(AppThemeColor color) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color.seed,
        brightness: Brightness.dark,
      ),
    );
  }

  static AppThemeColor fromString(String value) {
    return AppThemeColor.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppThemeColor.purple,
    );
  }

  static String toStringValue(AppThemeColor color) {
    return color.name;
  }

  static Color colorOf(AppThemeColor color) {
    return color.seed;
  }

  static String labelOf(AppThemeColor color) {
    return color.label;
  }
}
