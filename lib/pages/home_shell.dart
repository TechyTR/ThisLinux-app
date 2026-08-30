import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();

    _pages = [
      SystemInfoPage(
        selectedTheme: widget.selectedTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
      const NotesPage(),
      const AppInfoPage(),
    ];
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTheme != widget.selectedTheme) {
      _pages = [
        SystemInfoPage(
          selectedTheme: widget.selectedTheme,
          onThemeChanged: widget.onThemeChanged,
        ),
        const NotesPage(),
        const AppInfoPage(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'System',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'App',
          ),
        ],
      ),
    );
  }
}
