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
  static ThemeData build(
    AppThemeColor color,
    AppThemeStyle style,
  ) {
    switch (style) {
      case AppThemeStyle.normal:
        return _normal(color);

      case AppThemeStyle.liquidGlassLight:
        return _liquidGlassLight(color);

      case AppThemeStyle.liquidGlassDark:
        return _liquidGlassDark(color);
    }
  }

  static ThemeData _normal(
    AppThemeColor color,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color.seed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor:
          const Color(0xFF101010),
    );
  }

  static ThemeData _liquidGlassLight(
    AppThemeColor color,
  ) {
    final scheme =
        ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color:
            Colors.white.withOpacity(0.55),
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData _liquidGlassDark(
    AppThemeColor color,
  ) {
    final scheme =
        ColorScheme.fromSeed(
      seedColor: color.seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color:
            Colors.white.withOpacity(0.07),
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }

  static AppThemeColor colorFromString(
    String value,
  ) {
    return AppThemeColor.values.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          AppThemeColor.purple,
    );
  }

  static String colorToString(
    AppThemeColor color,
  ) {
    return color.name;
  }

  static AppThemeStyle styleFromString(
    String value,
  ) {
    return AppThemeStyle.values.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          AppThemeStyle.normal,
    );
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
