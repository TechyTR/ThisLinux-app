import 'package:flutter/material.dart';

enum AppThemeColor {
  purple,
  blue,
  green,
  orange,
}

class AppTheme {
  static ThemeData light(AppThemeColor color) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _getColor(color),
    );
  }

  static ThemeData dark(AppThemeColor color) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _getColor(color),
    );
  }

  static Color _getColor(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.purple:
        return Colors.deepPurple;

      case AppThemeColor.blue:
        return Colors.blue;

      case AppThemeColor.green:
        return Colors.green;

      case AppThemeColor.orange:
        return Colors.orange;
    }
  }

  static AppThemeColor fromString(String value) {
    switch (value) {
      case 'blue':
        return AppThemeColor.blue;

      case 'green':
        return AppThemeColor.green;

      case 'orange':
        return AppThemeColor.orange;

      case 'purple':
      default:
        return AppThemeColor.purple;
    }
  }

  static String toStringValue(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.purple:
        return 'purple';

      case AppThemeColor.blue:
        return 'blue';

      case AppThemeColor.green:
        return 'green';

      case AppThemeColor.orange:
        return 'orange';
    }
  }
}
