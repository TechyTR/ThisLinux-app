import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeColorKey = 'theme_color';
  static const String _themeStyleKey = 'theme_style';

  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeColorKey) ?? 'purple';
  }

  static Future<void> saveThemeColor(
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeColorKey,
      value,
    );
  }

  static Future<String> getThemeStyle() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeStyleKey) ?? 'normal';
  }

  static Future<void> saveThemeStyle(
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeStyleKey,
      value,
    );
  }
}
