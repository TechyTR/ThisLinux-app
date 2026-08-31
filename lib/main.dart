import 'package:flutter/material.dart';

import 'pages/boot_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ThisLinuxApp(),
  );
}

class ThisLinuxApp
    extends StatefulWidget {
  const ThisLinuxApp({
    super.key,
  });

  @override
  State<ThisLinuxApp> createState() =>
      _ThisLinuxAppState();
}

class _ThisLinuxAppState
    extends State<ThisLinuxApp> {
  AppThemeColor _selectedTheme =
      AppThemeColor.purple;

  AppThemeStyle _selectedStyle =
      AppThemeStyle.normal;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'ThisLinux',
      debugShowCheckedModeBanner:
          false,

      theme: AppTheme.build(
        _selectedTheme,
        _selectedStyle,
      ),

      home: BootScreen(
        selectedTheme:
            _selectedTheme,
        selectedStyle:
            _selectedStyle,
        onThemeChanged:
            (theme) async {
          setState(() {
            _selectedTheme = theme;
          });
        },
        onStyleChanged:
            (style) async {
          setState(() {
            _selectedStyle = style;
          });
        },
      ),
    );
  }
}
