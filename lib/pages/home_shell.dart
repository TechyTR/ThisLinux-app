import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_info_page.dart';
import 'notes_page.dart';
import 'system_info_page.dart';

class HomeShell extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Future<void> Function(AppThemeColor) onThemeChanged;

  const HomeShell({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  List<Widget> _buildPages() {
    return [
      SystemInfoPage(
        selectedTheme: widget.selectedTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
      const NotesPage(),
      const AppInfoPage(),
    ];
  }

  @override
  void initState() {
    super.initState();

    _pages = _buildPages();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTheme != widget.selectedTheme) {
      _pages = _buildPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
