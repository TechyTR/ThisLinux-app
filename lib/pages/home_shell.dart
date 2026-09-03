import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_info_page.dart';
import 'dashboard_page.dart';
import 'notes_page.dart';
import 'system_monitor_page.dart';

class HomeShell extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;
  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const HomeShell({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
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
    _pages = _buildPages();
  }

  List<Widget> _buildPages() => [
        DashboardPage(
          selectedTheme: widget.selectedTheme,
          selectedStyle: widget.selectedStyle,
          onThemeChanged: widget.onThemeChanged,
          onStyleChanged: widget.onStyleChanged,
        ),
        SystemMonitorPage(
          selectedTheme: widget.selectedTheme,
          selectedStyle: widget.selectedStyle,
          onThemeChanged: widget.onThemeChanged,
          onStyleChanged: widget.onStyleChanged,
        ),
        const NotesPage(),
        AppInfoPage(
          selectedTheme: widget.selectedTheme,
          selectedStyle: widget.selectedStyle,
          onThemeChanged: widget.onThemeChanged,
          onStyleChanged: widget.onStyleChanged,
        ),
      ];

  void _selectDestination(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTheme != widget.selectedTheme ||
        oldWidget.selectedStyle != widget.selectedStyle) {
      _pages = _buildPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: widget.selectedStyle != AppThemeStyle.normal,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _pages.length,
          (index) => RepaintBoundary(child: _pages[index]),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _selectDestination,
        accent: scheme.primary,
        mutedColor: scheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Hakkında',
          ),
        ],
      ),
    );
  }
}
