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
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThisLinux',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: BootScreen(
        onThemeChanged: (mode) {
          setState(() {
            _themeMode = mode;
          });
        },
      ),
    );
  }
}
