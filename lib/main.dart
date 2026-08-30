import 'package:flutter/material.dart';

import 'pages/boot_screen.dart';
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThisLinux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(_selectedTheme),
      darkTheme: AppTheme.dark(_selectedTheme),
      themeMode: ThemeMode.dark,
      home: BootScreen(
        selectedTheme: _selectedTheme,
        onThemeChanged: (theme) async {
          setState(() {
            _selectedTheme = theme;
          });
        },
      ),
    );
  }
}
