import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isLiquidGlass =
        Theme.of(context).scaffoldBackgroundColor ==
                Colors.white ||
            Theme.of(context).scaffoldBackgroundColor ==
                Colors.black;

    if (!isLiquidGlass) {
      return NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            onDestinationSelected,
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
              color: theme.brightness ==
                      Brightness.light
                  ? Colors.white.withOpacity(0.55)
                  : Colors.black.withOpacity(0.55),
              borderRadius:
                  BorderRadius.circular(28),
              border: Border.all(
                color:
                    Colors.white.withOpacity(0.20),
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
    final selected =
        currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onDestinationSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withOpacity(0.22)
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(22),
              border: selected
                  ? Border.all(
                      color:
                          Colors.white.withOpacity(
                        0.22,
                      ),
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            accent.withOpacity(0.16),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  child: Icon(
                    selected
                        ? selectedIcon
                        : icon,
                    color: selected
                        ? accent
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  style: TextStyle(
                    fontSize: selected ? 12 : 11,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? accent
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
