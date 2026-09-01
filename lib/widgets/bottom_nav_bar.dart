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
    final scheme = Theme.of(context).colorScheme;

    if (selectedStyle == AppThemeStyle.normal) {
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

    final isLight =
        selectedStyle ==
            AppThemeStyle.liquidGlassLight;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 22,
            sigmaY: 22,
          ),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withOpacity(0.50)
                  : Colors.black.withOpacity(0.55),
              borderRadius:
                  BorderRadius.circular(28),
              border: Border.all(
                color: isLight
                    ? Colors.white.withOpacity(0.82)
                    : Colors.white.withOpacity(0.18),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    constraints.maxWidth / 3;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(
                        milliseconds: 430,
                      ),
                      curve:
                          Curves.easeOutCubic,
                      left:
                          itemWidth *
                              currentIndex +
                          6,
                      top: 6,
                      width: itemWidth - 12,
                      height: 60,
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 430,
                          ),
                          decoration:
                              BoxDecoration(
                            color: isLight
                                ? scheme.primary
                                    .withOpacity(0.34)
                                : scheme.primary
                                    .withOpacity(0.28),
                            borderRadius:
                                BorderRadius.circular(
                              22,
                            ),
                            border: Border.all(
                              color: isLight
                                  ? scheme.primary
                                      .withOpacity(0.58)
                                  : Colors.white
                                      .withOpacity(0.22),
                              width:
                                  isLight
                                      ? 1.3
                                      : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme
                                    .primary
                                    .withOpacity(
                                  isLight
                                      ? 0.38
                                      : 0.22,
                                ),
                                blurRadius:
                                    isLight
                                        ? 20
                                        : 18,
                                spreadRadius:
                                    isLight
                                        ? 1.5
                                        : 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
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
                  ],
                );
              },
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

    final mutedColor =
        Theme.of(context)
            .colorScheme
            .onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque,
        onTap: () {
          onDestinationSelected(index);
        },
        child: SizedBox(
          height: 72,
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale:
                      selected ? 1.08 : 1.0,
                  duration:
                      const Duration(
                    milliseconds: 300,
                  ),
                  curve:
                      Curves.easeOutCubic,
                  child:
                      AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 220,
                    ),
                    child: Icon(
                      selected
                          ? selectedIcon
                          : icon,
                      key: ValueKey(
                        '$index-$selected',
                      ),
                      color: selected
                          ? accent
                          : mutedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration:
                      const Duration(
                    milliseconds: 220,
                  ),
                  style: TextStyle(
                    fontSize:
                        selected ? 12 : 11,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: selected
                        ? accent
                        : mutedColor,
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
