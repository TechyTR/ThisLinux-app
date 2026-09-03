import 'package:flutter/services.dart';

class GraphicsBenchmarkResult {
  final double averageFps;
  final double minimumFps;
  final double onePercentLow;
  final int droppedFrames;
  final int renderedFrames;
  final double frameTimeMs;
  final double stutterRate;

  const GraphicsBenchmarkResult({
    required this.averageFps,
    required this.minimumFps,
    required this.onePercentLow,
    required this.droppedFrames,
    required this.renderedFrames,
    required this.frameTimeMs,
    required this.stutterRate,
  });

  factory GraphicsBenchmarkResult.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    double number(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    int integer(dynamic value) {
      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    return GraphicsBenchmarkResult(
      averageFps:
          number(map['averageFps']),
      minimumFps:
          number(map['minimumFps']),
      onePercentLow:
          number(map['onePercentLow']),
      droppedFrames:
          integer(map['droppedFrames']),
      renderedFrames:
          integer(map['renderedFrames']),
      frameTimeMs:
          number(map['frameTimeMs']),
      stutterRate:
          number(map['stutterRate']),
    );
  }
}

class BenchmarkGraphicsService {
  static const MethodChannel _channel =
      MethodChannel(
    'org.test.thislinux/benchmark_graphics',
  );

  static Future<GraphicsBenchmarkResult?>
      run() async {
    try {
      final result =
          await _channel.invokeMethod<
              Map<dynamic, dynamic>>(
        'run4K120Benchmark',
      );

      if (result == null) {
        return null;
      }

      return GraphicsBenchmarkResult
          .fromMap(result);
    } catch (_) {
      return null;
    }
  }

  static Future<double?>
      getDisplayRefreshRate() async {
    try {
      final result =
          await _channel.invokeMethod<
              double>(
        'getDisplayRefreshRate',
      );

      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<void>
      cancel() async {
    try {
      await _channel.invokeMethod(
        'cancel4K120Benchmark',
      );
    } catch (_) {}
  }
}
