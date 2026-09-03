import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'benchmark_graphics_service.dart';

class BenchmarkResult {
  final int singleCore;
  final int multiCore;
  final int ram;
  final int storage;
  final int graphics;
  final int mixed;
  final int total;

  final GraphicsBenchmarkResult? graphicsResult;

  const BenchmarkResult({
    required this.singleCore,
    required this.multiCore,
    required this.ram,
    required this.storage,
    required this.graphics,
    required this.mixed,
    required this.total,
    required this.graphicsResult,
  });
}

class BenchmarkService {
  static bool _cancelled = false;

  static Future<BenchmarkResult?> run({
    void Function(String status, double progress)?
        onProgress,
  }) async {
    _cancelled = false;

    void progress(
      String status,
      double value,
    ) {
      onProgress?.call(
        status,
        value.clamp(0.0, 1.0),
      );
    }

    try {
      progress(
        'CPU tek çekirdek testi hazırlanıyor...',
        0.02,
      );

      final singleCore =
          await _singleCoreBenchmark(
        onProgress: (value) {
          progress(
            'CPU tek çekirdek test ediliyor...',
            0.02 + value * 0.18,
          );
        },
      );

      if (_cancelled) return null;

      progress(
        'CPU çoklu çekirdek testi hazırlanıyor...',
        0.20,
      );

      final multiCore =
          await _multiCoreBenchmark(
        onProgress: (value) {
          progress(
            'CPU çoklu çekirdek test ediliyor...',
            0.20 + value * 0.23,
          );
        },
      );

      if (_cancelled) return null;

      progress(
        'RAM bant genişliği ölçülüyor...',
        0.43,
      );

      final ram =
          await _ramBenchmark(
        onProgress: (value) {
          progress(
            'RAM test ediliyor...',
            0.43 + value * 0.14,
          );
        },
      );

      if (_cancelled) return null;

      progress(
        'Depolama performansı ölçülüyor...',
        0.57,
      );

      final storage =
          await _storageBenchmark(
        onProgress: (value) {
          progress(
            'Depolama test ediliyor...',
            0.57 + value * 0.14,
          );
        },
      );

      if (_cancelled) return null;

      progress(
        'Gerçek 4K 120 FPS grafik testi başlatılıyor...',
        0.71,
      );

      final graphicsResult =
          await BenchmarkGraphicsService.run();

      if (_cancelled) return null;

      final graphics =
          graphicsResult == null
              ? 0
              : _graphicsScore(
                  graphicsResult,
                );

      progress(
        'Karma sistem testi çalışıyor...',
        0.86,
      );

      final mixed =
          await _mixedBenchmark(
        onProgress: (value) {
          progress(
            'CPU + RAM karma testi...',
            0.86 + value * 0.10,
          );
        },
      );

      if (_cancelled) return null;

      progress(
        'Stellar Score hesaplanıyor...',
        0.98,
      );

      final total =
          _calculateTotal(
        singleCore: singleCore,
        multiCore: multiCore,
        ram: ram,
        storage: storage,
        graphics: graphics,
        mixed: mixed,
      );

      progress(
        'Benchmark tamamlandı.',
        1.0,
      );

      return BenchmarkResult(
        singleCore: singleCore,
        multiCore: multiCore,
        ram: ram,
        storage: storage,
        graphics: graphics,
        mixed: mixed,
        total: total,
        graphicsResult: graphicsResult,
      );
    } catch (_) {
      return null;
    }
  }

  static void cancel() {
    _cancelled = true;

    BenchmarkGraphicsService.cancel();
  }

  static int _calculateTotal({
    required int singleCore,
    required int multiCore,
    required int ram,
    required int storage,
    required int graphics,
    required int mixed,
  }) {
    final score =
        singleCore * 0.20 +
        multiCore * 0.25 +
        ram * 0.15 +
        storage * 0.15 +
        graphics * 0.10 +
        mixed * 0.15;

    return score.round();
  }

  static int _graphicsScore(
    GraphicsBenchmarkResult result,
  ) {
    if (!result.isValid) {
      return 0;
    }

    const targetFps = 120.0;

    final averageRatio =
        (result.averageFps / targetFps)
            .clamp(0.0, 1.0);

    final lowRatio =
        (result.onePercentLow / targetFps)
            .clamp(0.0, 1.0);

    final minimumRatio =
        (result.minimumFps / targetFps)
            .clamp(0.0, 1.0);

    final dropPenalty =
        (1.0 -
                result.stutterRate /
                    100.0)
            .clamp(0.0, 1.0);

    final processingScore =
        if (result.processingAverageMs <= 0) {
          1.0;
        } else {
          (1.0 -
                  result.processingAverageMs /
                      16.67)
              .clamp(0.0, 1.0);
        };

    final score =
        averageRatio * 0.35 +
        lowRatio * 0.25 +
        minimumRatio * 0.15 +
        dropPenalty * 0.15 +
        processingScore * 0.10;

    return (score * 10000)
        .round()
        .clamp(0, 10000);
  }

  static Future<int> _singleCoreBenchmark({
    void Function(double progress)?
        onProgress,
  }) async {
    return Isolate.run(() {
      final stopwatch =
          Stopwatch()..start();

      const duration =
          Duration(seconds: 3);

      double value = 0.123456789;

      int operations = 0;

      while (
          stopwatch.elapsed <
              duration) {
        value =
            sin(value) *
                cos(value) +
            sqrt(
              value.abs() + 1.0,
            );

        value =
            value -
                value.floorToDouble();

        operations += 4;
      }

      stopwatch.stop();

      if (value.isNaN) {
        return 0;
      }

      final operationsPerSecond =
          operations /
              stopwatch.elapsedMicroseconds *
              1000000;

      final score =
          sqrt(
                operationsPerSecond,
              ) *
              2.0;

      return score
          .round()
          .clamp(0, 10000);
    });
  }

  static Future<int> _multiCoreBenchmark({
    void Function(double progress)?
        onProgress,
  }) async {
    final cores =
        max(
          1,
          Platform.numberOfProcessors,
        );

    final receivePort =
        ReceivePort();

    final isolates =
        <Isolate>[];

    int completed = 0;

    try {
      for (int i = 0; i < cores; i++) {
        final isolate =
            await Isolate.spawn(
          _multiCoreWorker,
          receivePort.sendPort,
        );

        isolates.add(isolate);
      }

      final stopwatch =
          Stopwatch()..start();

      final expected =
          cores;

      await for (
        final message
        in receivePort
      ) {
        if (message is int) {
          completed++;

          onProgress?.call(
            completed /
                expected,
          );

          if (
              completed >=
                  expected) {
            break;
          }
        }
      }

      stopwatch.stop();

     
