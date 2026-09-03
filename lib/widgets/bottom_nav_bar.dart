import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accent;
  final Color mutedColor;
  final List<BottomNavigationBarItem> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.accent,
    required this.mutedColor,
    required this.items,
  });

  Widget _icon(BottomNavigationBarItem item, bool selected) {
    final source = selected ? item.activeIcon : item.icon;
    return IconTheme(
      data: IconThemeData(
        size: 22,
        color: selected ? accent : mutedColor,
      ),
      child: source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGlass = theme.scaffoldBackgroundColor.a < 0.99;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(28, 4, 28, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isGlass ? 18 : 0,
            sigmaY: isGlass ? 18 : 0,
          ),
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                final selectedLeft = itemWidth * currentIndex + 3;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      left: selectedLeft,
                      top: 3,
                      width: itemWidth - 6,
                      height: 55,
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.075)
                                    : Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.68),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.13),
                                    blurRadius: 16,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: 1.2,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(
                                          alpha: isDark ? 0.34 : 0.72,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final selected = index == currentIndex;

                        return Expanded(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(19),
                              onTap: () => onTap(index),
                              splashColor: accent.withValues(alpha: 0.14),
                              highlightColor: accent.withValues(alpha: 0.07),
                              child: AnimatedScale(
                                scale: selected ? 1.045 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 180),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _icon(item, selected),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      style: theme.textTheme.labelSmall!.copyWith(
                                        color: selected ? accent : mutedColor,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      child: Text(item.label ?? ''),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
}
