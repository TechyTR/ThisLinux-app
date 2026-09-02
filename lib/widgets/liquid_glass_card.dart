import 'dart:ui';

import 'package:flutter/material.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  final Color? tint;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
    this.blur = 22,
    this.opacity = 0.10,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight =
        Theme.of(context).brightness == Brightness.light;

    final glassTint = tint ?? Colors.white;

    final content = Padding(
      padding: padding,
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,

            // Ana yüzey özellikle saydam.
            color: glassTint.withOpacity(
              isLight ? opacity * 1.35 : opacity,
            ),

            // Belirgin cam kenarı.
            border: Border.all(
              color: Colors.white.withOpacity(
                isLight ? 0.58 : 0.22,
              ),
              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isLight ? 0.08 : 0.20,
                ),
                blurRadius: 24,
                spreadRadius: -7,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              content,

              // Üst kenarda cam yansıması.
              Positioned(
                left: 12,
                right: 12,
                top: 0,
                height: 1.2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(
                            isLight ? 0.75 : 0.35,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Çok hafif iç buğu/highlight.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(
                            isLight ? 0.09 : 0.045,
                          ),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

