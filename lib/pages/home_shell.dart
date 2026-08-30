import 'package:flutter/material.dart';

import 'pages/boot_screen.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ThisLinuxApp());
}

class ThisLinuxApp extends StatefulWidget {
  const ThisLinuxApp({super.key});

  @override
  State<ThisLinuxApp> createState() => _ThisLinuxAppState();
}

class _ThisLinuxAppState extends State<ThisLinuxApp> {
  AppThemeColor _selectedTheme = AppThemeColor.purple;
  AppThemeStyle _selectedStyle = AppThemeStyle.normal;

  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final colorValue =
        await PreferencesService.getThemeColor();

    final styleValue =
        await PreferencesService.getThemeStyle();

    if (!mounted) return;

    setState(() {
      _selectedTheme =
          AppTheme.colorFromString(colorValue);

      _selectedStyle =
          AppTheme.styleFromString(styleValue);

      _preferencesLoaded = true;
    });
  }

  Future<void> _changeTheme(
    AppThemeColor color,
  ) async {
    setState(() {
      _selectedTheme = color;
    });

    await PreferencesService.saveThemeColor(
      AppTheme.colorToString(color),
    );
  }

  Future<void> _changeStyle(
    AppThemeStyle style,
  ) async {
    setState(() {
      _selectedStyle = style;
    });

    await PreferencesService.saveThemeStyle(
      AppTheme.styleToString(style),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_preferencesLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'ThisLinux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        _selectedTheme,
        _selectedStyle,
      ),
      home: BootScreen(
        selectedTheme: _selectedTheme,
        selectedStyle: _selectedStyle,
        onThemeChanged: _changeTheme,
        onStyleChanged: _changeStyle,
      ),
    );
  }
}

Bunu yapınca 9 tamam. Ardından 10. adıma geçebiliriz.
