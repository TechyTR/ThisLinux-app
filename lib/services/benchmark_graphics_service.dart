import 'dart:async';

import 'package:flutter/services.dart';

class GraphicsBenchmarkResult {
  final double averageFps;
  final double minimumFps;
  final double onePercentLow;
  final int droppedFrames;
  final int renderedFrames;
  final double frameTimeMs;
  final double stutterRate;
  final int videoWidth;
  final int videoHeight;
  final double videoFps;
  final double processingAverageMs;

  const GraphicsBenchmarkResult({
    required this.averageFps,
    required this.minimumFps,
    required this.onePercentLow,
    required this.droppedFrames,
    required this.renderedFrames,
    required this.frameTimeMs,
    required this.stutterRate,
    required this.videoWidth,
    required this.videoHeight,
    required this.videoFps,
    required this.processingAverageMs,
  });

  factory GraphicsBenchmarkResult.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    double toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0.0;
    }

    int toInt(dynamic value) {
      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    return GraphicsBenchmarkResult(
      averageFps: toDouble(
        map['averageFps'],
      ),
      minimumFps: toDouble(
        map['minimumFps'],
      ),
      onePercentLow: toDouble(
        map['onePercentLow'],
      ),
      droppedFrames: toInt(
        map['droppedFrames'],
      ),
      renderedFrames: toInt(
        map['renderedFrames'],
      ),
      frameTimeMs: toDouble(
        map['frameTimeMs'],
      ),
      stutterRate: toDouble(
        map['stutterRate'],
      ),
      videoWidth: toInt(
        map['videoWidth'],
      ),
      videoHeight: toInt(
        map['videoHeight'],
      ),
      videoFps: toDouble(
        map['videoFps'],
      ),
      processingAverageMs: toDouble(
        map['processingAverageMs'],
      ),
    );
  }

  bool get isValid {
    return videoWidth >= 3840 &&
        videoHeight >= 2160 &&
        videoFps >= 119 &&
        renderedFrames > 0 &&
        averageFps > 0;
  }

  double get resolutionScore {
    if (videoWidth >= 3840 &&
        videoHeight >= 2160) {
      return 1.0;
    }

    return 0.0;
  }

  double get refreshScore {
    if (videoFps >= 120) {
      return 1.0;
    }

    if (videoFps >= 60) {
      return 0.5;
    }

    return 0.0;
  }
}

class BenchmarkGraphicsService {
  static const MethodChannel _channel =
      MethodChannel(
    'org.test.thislinux/benchmark_graphics',
  );

  static Future<GraphicsBenchmarkResult?>
      run() async {
    final completer =
        Completer<GraphicsBenchmarkResult?>();

    late final Future<dynamic> Function(
      MethodCall,
    ) handler;

    handler = (call) async {
      switch (call.method) {
        case 'benchmarkResult':
          if (!completer.isCompleted) {
            final arguments =
                call.arguments;

            if (arguments is Map) {
              completer.complete(
                GraphicsBenchmarkResult
                    .fromMap(
                  arguments,
                ),
              );
            } else {
              completer.complete(null);
            }
          }
          break;

        case 'benchmarkCancelled':
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          break;
      }

      return null;
    };

    _channel.setMethodCallHandler(
      handler,
    );

    try {
      await _channel.invokeMethod(
        'run4K120Benchmark',
      );

      return await completer.future.timeout(
        const Duration(
          minutes: 5,
        ),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      _channel.setMethodCallHandler(
        null,
      );
    }
  }

  static Future<double?> getDisplayRefreshRate() async {
    try {
      final result =
          await _channel.invokeMethod<num>(
        'getDisplayRefreshRate',
      );

      return result?.toDouble();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod(
        'cancel4K120Benchmark',
      );
    } catch (_) {}
  }
}
