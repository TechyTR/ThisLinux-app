import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_info_page.dart';
import 'notes_page.dart';
import 'system_info_page.dart';

class HomeShell extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(
    AppThemeColor,
  ) onThemeChanged;

  final Future<void> Function(
    AppThemeStyle,
  ) onStyleChanged;

  const HomeShell({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<HomeShell> createState() =>
      _HomeShellState();
}

class _HomeShellState
    extends State<HomeShell> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
  }

  List<Widget> _buildPages() {
    return [
      SystemInfoPage(
        selectedTheme:
            widget.selectedTheme,
        selectedStyle:
            widget.selectedStyle,
        onThemeChanged:
            widget.onThemeChanged,
        onStyleChanged:
            widget.onStyleChanged,
      ),
      const NotesPage(),
      AppInfoPage(
        selectedTheme:
            widget.selectedTheme,
        selectedStyle:
            widget.selectedStyle,
        onThemeChanged:
            widget.onThemeChanged,
        onStyleChanged:
            widget.onStyleChanged,
      ),
    ];
  }

  @override
  void didUpdateWidget(
    covariant HomeShell oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTheme !=
            widget.selectedTheme ||
        oldWidget.selectedStyle !=
            widget.selectedStyle) {
      setState(() {
        _pages = _buildPages();
      });
    }
  }

  void _selectDestination(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar:
          BottomNavBar(
        currentIndex:
            _currentIndex,
        selectedStyle:
            widget.selectedStyle,
        onDestinationSelected:
            _selectDestination,
      ),
    );
  }
}
