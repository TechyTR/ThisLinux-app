import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'theme_color';

  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeKey) ?? 'purple';
  }

  static Future<void> saveThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeKey, color);
  }
}
