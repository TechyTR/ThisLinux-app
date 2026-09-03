import 'package:flutter/material.dart';

class BenchmarkVideoSurface
    extends StatelessWidget {
  final bool running;
  final VoidCallback? onReady;

  const BenchmarkVideoSurface({
    super.key,
    required this.running,
    this.onReady,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        color: Colors.black,
        border: Border.all(
          color: scheme.primary
              .withOpacity(0.35),
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                running
                    ? Icons
                        .ondemand_video_rounded
                    : Icons
                        .play_circle_outline_rounded,
                size: 52,
                color: Colors.white
                    .withOpacity(0.8),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                running
                    ? '4K 120 FPS video testi çalışıyor'
                    : '4K 120 FPS Grafik Testi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
                textAlign:
                    TextAlign.center,
              ),
              if (running) ...[
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Gerçek video decoder ölçümü',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black
                    .withOpacity(0.65),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Text(
                '3840 × 2160 • 120 FPS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
