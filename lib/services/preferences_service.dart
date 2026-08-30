import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'theme_color';

  static Future<int> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 0;
  }

  static Future<void> saveThemeColor(int colorIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, colorIndex);
  }

  static ThemeMode getThemeMode() {
    return ThemeMode.system;
  }
}
