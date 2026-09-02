import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_info_page.dart';
import 'dashboard_page.dart';
import 'notes_page.dart';
import 'system_info_page.dart';
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

  List<Widget> _buildPages() {
    return [
      DashboardPage(
        selectedTheme: widget.selectedTheme,
        selectedStyle: widget.selectedStyle,
        onThemeChanged: widget.onThemeChanged,
        onStyleChanged: widget.onStyleChanged,
        onSystemInfo: () => _openPage(1),
        onSystemMonitor: () => _openPage(2),
        onNotes: () => _openPage(3),
        onAppInfo: () => _openPage(4),
      ),
      SystemInfoPage(
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
  }

  void _openPage(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _selectDestination(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTheme != widget.selectedTheme ||
        oldWidget.selectedStyle != widget.selectedStyle) {
      setState(() {
        _pages = _buildPages();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: widget.selectedStyle != AppThemeStyle.normal,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (
          Widget? currentChild,
          List<Widget> previousChildren,
        ) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final slide = Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        selectedStyle: widget.selectedStyle,
        onDestinationSelected: _selectDestination,
      ),
    );
  }
}
