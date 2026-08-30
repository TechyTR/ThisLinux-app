import 'package:flutter/material.dart';

enum AppThemeColor {
  purple,
  blue,
  green,
  orange,
}

enum AppThemeStyle {
  normal,
  liquidGlassLight,
  liquidGlassDark,
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

extension AppThemeStyleExtension on AppThemeStyle {
  String get label {
    switch (this) {
      case AppThemeStyle.normal:
        return 'Normal';
      case AppThemeStyle.liquidGlassLight:
        return 'Liquid Glass Light';
      case AppThemeStyle.liquidGlassDark:
        return 'Liquid Glass Dark';
    }
  }
}

class AppTheme {
  static ThemeData normal(
    AppThemeColor color,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B0F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: color.seed,
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData liquidGlassLight(
    AppThemeColor color,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData liquidGlassDark(
    AppThemeColor color,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData build(
    AppThemeColor color,
    AppThemeStyle style,
  ) {
    switch (style) {
      case AppThemeStyle.normal:
        return normal(color);

      case AppThemeStyle.liquidGlassLight:
        return liquidGlassLight(color);

      case AppThemeStyle.liquidGlassDark:
        return liquidGlassDark(color);
    }
  }

  static AppThemeColor colorFromString(
    String value,
  ) {
    return AppThemeColor.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppThemeColor.purple,
    );
  }

  static AppThemeStyle styleFromString(
    String value,
  ) {
    return AppThemeStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => AppThemeStyle.normal,
    );
  }

  static String colorToString(
    AppThemeColor color,
  ) {
    return color.name;
  }

  static String styleToString(
    AppThemeStyle style,
  ) {
    return style.name;
  }

  static Color colorOf(
    AppThemeColor color,
  ) {
    return color.seed;
  }

  static String labelOf(
    AppThemeColor color,
  ) {
    return color.label;
  }

  static String styleLabelOf(
    AppThemeStyle style,
  ) {
    return style.label;
  }
}
