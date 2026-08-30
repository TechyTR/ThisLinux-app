import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppThemeStyle selectedStyle;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.selectedStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isLiquidGlass =
        selectedStyle != AppThemeStyle.normal;

    if (!isLiquidGlass) {
      return NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
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
      );
    }

    final isLight =
        selectedStyle == AppThemeStyle.liquidGlassLight;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withOpacity(0.55)
                  : Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isLight
                    ? Colors.white.withOpacity(0.65)
                    : Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _item(
                  context,
                  Icons.memory_outlined,
                  Icons.memory,
                  'System',
                  0,
                  scheme.primary,
                ),
                _item(
                  context,
                  Icons.note_outlined,
                  Icons.note,
                  'Notes',
                  1,
                  scheme.primary,
                ),
                _item(
                  context,
                  Icons.info_outline,
                  Icons.info,
                  'App',
                  2,
                  scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    Color accent,
  ) {
    final selected = currentIndex == index;
    final isLight =
        selectedStyle == AppThemeStyle.liquidGlassLight;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onDestinationSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withOpacity(
                      isLight ? 0.18 : 0.28,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: selected
                 
