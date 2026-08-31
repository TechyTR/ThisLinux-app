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
    final scheme =
        Theme.of(context).colorScheme;

    if (selectedStyle ==
        AppThemeStyle.normal) {
      return NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected:
            onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.memory_outlined,
            ),
            selectedIcon: Icon(
              Icons.memory,
            ),
            label: 'System',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.note_outlined,
            ),
            selectedIcon: Icon(
              Icons.note,
            ),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.info_outline,
            ),
            selectedIcon: Icon(
              Icons.info,
            ),
            label: 'App',
          ),
        ],
      );
    }

    final isLight =
        selectedStyle ==
            AppThemeStyle
                .liquidGlassLight;

    return SafeArea(
      minimum:
          const EdgeInsets.fromLTRB(
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
            decoration:
                BoxDecoration(
              color: isLight
                  ? Colors.white
                      .withOpacity(0.52)
                  : Colors.black
                      .withOpacity(0.55),
              borderRadius:
                  BorderRadius.circular(28),
              border: Border.all(
                color: isLight
                    ? Colors.white
                        .withOpacity(0.72)
                    : Colors.white
                        .withOpacity(0.18),
              ),
            ),
            child: LayoutBuilder(
              builder:
                  (context, constraints) {
                final itemWidth =
                    constraints.maxWidth /
                        3;

                return Stack(
                  children: [
                    // Kayan Liquid Glass kapsülü
                    AnimatedPositioned(
                      duration:
                          const Duration(
                        milliseconds: 420,
                      ),
                      curve:
                          Curves.easeOutCubic,
                      left:
                          itemWidth *
                              currentIndex +
                          6,
                      top: 6,
                      width:
                          itemWidth - 12,
                      height: 60,
                      child:
                          IgnorePointer(
                        child:
                            AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 420,
                          ),
                          decoration:
                              BoxDecoration(
                            color: scheme
                                .primary
                                .withOpacity(
                              isLight
                                  ? 0.16
                                  : 0.27,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              22,
                            ),
                            border:
                                Border.all(
                              color: Colors
                                  .white
                                  .withOpacity(
                                isLight
                                    ? 0.68
                                    : 0.20,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme
                                    .primary
                                    .withOpacity(
                                  isLight
                                      ? 0.18
                                      : 0.20,
                                ),
                                blurRadius: 18,
                                spreadRadius: 1,
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
                          Icons
                              .memory_outlined,
                          Icons.memory,
                          'System',
                          0,
                          scheme.primary,
                        ),
                        _item(
                          context,
                          Icons
                              .note_outlined,
                          Icons.note,
                          'Notes',
                          1,
                          scheme.primary,
                        ),
                        _item(
                          context,
                          Icons
                              .info_outline,
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

    return Expanded(
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque,
        onTap: () =>
            onDestinationSelected(index),
        child: SizedBox(
          height: 72,
          child: Center(
            child: AnimatedScale(
              scale: selected ? 1.04 : 1.0,
              duration:
                  const Duration(
                milliseconds: 300,
              ),
              curve:
                  Curves.easeOutCubic,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
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
                          : Theme.of(
                              context,
                            )
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
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
                          : Theme.of(
                              context,
                            )
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                    child:
                        Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
