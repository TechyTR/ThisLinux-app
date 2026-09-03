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

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).brightness == Brightness.dark;
    final isGlass = Theme.of(context).scaffoldBackgroundColor.a < 0.99;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isGlass ? 18 : 0, sigmaY: isGlass ? 18 : 0),
          child: Container(
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: style
                  ? Colors.black.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: style
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;

                return Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                        -1 + (2 * currentIndex / (items.length - 1)),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / items.length,
                        heightFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: style ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(19),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.16),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
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
                          child: Semantics(
                            button: true,
                            selected: selected,
                            label: item.label,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(19),
                              onTap: () => onTap(index),
                              splashColor: accent.withValues(alpha: 0.12),
                              highlightColor: accent.withValues(alpha: 0.06),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: selected ? 1 : 0),
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 1 + (0.06 * value),
                                    child: child,
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconTheme(
                                      data: IconThemeData(
                                        size: 24,
                                        color: selected ? accent : mutedColor,
                                      ),
                                      child: selected
                                          ? item.activeIcon
                                          : item.icon,
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 160),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
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
