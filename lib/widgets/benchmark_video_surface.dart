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
        alignment:
            Alignment.center,
        children: [
          if (!running)
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .ondemand_video_rounded,
                  size: 48,
                  color:
                      Colors.white
                          .withOpacity(
                    0.75,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  '4K 120 FPS Grafik Testi',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            )
          else
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  '4K 120 FPS test hazırlanıyor...',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),

          if (running)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withOpacity(
                    0.65,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Text(
                  '4K • 120 FPS',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 11,
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
