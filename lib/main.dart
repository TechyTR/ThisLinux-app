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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await PreferencesService.getThemeColor();

    if (!mounted) return;

    setState(() {
      _selectedTheme = AppTheme.fromString(savedTheme);
    });
  }

  Future<void> _changeTheme(AppThemeColor theme) async {
    setState(() {
      _selectedTheme = theme;
    });

    await PreferencesService.saveThemeColor(
      AppTheme.toStringValue(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThisLinux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(_selectedTheme),
      darkTheme: AppTheme.dark(_selectedTheme),
      themeMode: ThemeMode.system,
      home: BootScreen(
        selectedTheme: _selectedTheme,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}
