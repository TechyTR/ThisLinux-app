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
    void Function(String status, double progress)? onProgress,
  }) async {
    _cancelled = false;

    void progress(String status, double value) {
      onProgress?.call(status, value.clamp(0.0, 1.0));
    }

    try {
      progress('CPU tek çekirdek testi hazırlanıyor...', 0.02);
      final singleCore = await _singleCoreBenchmark();
      if (_cancelled) return null;

      progress('CPU tek çekirdek testi tamamlandı.', 0.20);
      final multiCore = await _multiCoreBenchmark(
        onProgress: (value) {
          progress('CPU çoklu çekirdek test ediliyor...', 0.20 + value * 0.23);
        },
      );
      if (_cancelled) return null;

      progress('RAM bant genişliği ölçülüyor...', 0.43);
      final ram = await _ramBenchmark(
        onProgress: (value) {
          progress('RAM test ediliyor...', 0.43 + value * 0.14);
        },
      );
      if (_cancelled) return null;

      progress('Depolama performansı ölçülüyor...', 0.57);
      final storage = await _storageBenchmark(
        onProgress: (value) {
          progress('Depolama test ediliyor...', 0.57 + value * 0.14);
        },
      );
      if (_cancelled) return null;

      progress('Gerçek 4K 120 FPS grafik testi başlatılıyor...', 0.71);
      final graphicsResult = await BenchmarkGraphicsService.run();
      if (_cancelled) return null;

      final graphics = graphicsResult == null ? 0 : _graphicsScore(graphicsResult);

      progress('Karma sistem testi çalışıyor...', 0.86);
      final mixed = await _mixedBenchmark(
        onProgress: (value) {
          progress('CPU + RAM karma testi...', 0.86 + value * 0.10);
        },
      );
      if (_cancelled) return null;

      progress('Stellar Score hesaplanıyor...', 0.98);
      final total = _calculateTotal(
        singleCore: singleCore,
        multiCore: multiCore,
        ram: ram,
        storage: storage,
        graphics: graphics,
        mixed: mixed,
      );

      progress('Benchmark tamamlandı.', 1.0);
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
    final score = singleCore * 0.20 +
        multiCore * 0.25 +
        ram * 0.15 +
        storage * 0.15 +
        graphics * 0.10 +
        mixed * 0.15;
    return score.round().clamp(0, 10000);
  }

  static int _graphicsScore(GraphicsBenchmarkResult result) {
    if (!result.isValid) return 0;

    const targetFps = 120.0;
    final averageRatio = (result.averageFps / targetFps).clamp(0.0, 1.0);
    final lowRatio = (result.onePercentLow / targetFps).clamp(0.0, 1.0);
    final minimumRatio = (result.minimumFps / targetFps).clamp(0.0, 1.0);
    final dropPenalty = (1.0 - result.stutterRate / 100.0).clamp(0.0, 1.0);
    final processingScore = result.processingAverageMs <= 0
        ? 1.0
        : (1.0 - result.processingAverageMs / 16.67).clamp(0.0, 1.0);

    final score = averageRatio * 0.35 +
        lowRatio * 0.25 +
        minimumRatio * 0.15 +
        dropPenalty * 0.15 +
        processingScore * 0.10;
    return (score * 10000).round().clamp(0, 10000);
  }

  static Future<int> _singleCoreBenchmark() async {
    return Isolate.run(() => _cpuWork());
  }

  static Future<int> _multiCoreBenchmark({
    void Function(double progress)? onProgress,
  }) async {
    final cores = min(8, max(1, Platform.numberOfProcessors));
    var completed = 0;

    final futures = List<Future<int>>.generate(cores, (_) async {
      final result = await Isolate.run(() => _cpuWork());
      completed++;
      onProgress?.call(completed / cores);
      return result;
    });

    final results = await Future.wait(futures);
    if (results.isEmpty) return 0;

    final total = results.fold<int>(0, (sum, value) => sum + value);
    return (total * 1.15).round().clamp(0, 10000);
  }

  static int _cpuWork() {
    final stopwatch = Stopwatch()..start();
    const duration = Duration(seconds: 2);
    var value = 0.123456789;
    var operations = 0;

    while (stopwatch.elapsed < duration) {
      value = sin(value) * cos(value) + sqrt(value.abs() + 1.0);
      value -= value.floorToDouble();
      value = sin(value + 0.37) * 0.5 + 0.5;
      operations += 6;
    }

    stopwatch.stop();
    if (value.isNaN || operations <= 0) return 0;

    final operationsPerSecond =
        operations / max(1, stopwatch.elapsedMicroseconds) * 1000000.0;
    return (sqrt(operationsPerSecond) * 2.0).round().clamp(0, 10000);
  }

  static Future<int> _ramBenchmark({
    void Function(double progress)? onProgress,
  }) async {
    return Isolate.run(() {
      const size = 16 * 1024 * 1024;
      const rounds = 6;
      final source = Uint8List(size);
      final destination = Uint8List(size);
      final random = Random(42);

      for (var i = 0; i < source.length; i += 4096) {
        source[i] = random.nextInt(256);
      }

      final stopwatch = Stopwatch()..start();
      var checksum = 0;
      for (var round = 0; round < rounds; round++) {
        destination.setAll(0, source);
        for (var i = 0; i < destination.length; i += 4096) {
          checksum ^= destination[i];
        }
      }
      stopwatch.stop();

      if (checksum < -1) return 0;
      final seconds = max(0.001, stopwatch.elapsedMicroseconds / 1000000.0);
      final megabytesPerSecond = (size * rounds * 2) / 1024 / 1024 / seconds;
      return (sqrt(megabytesPerSecond) * 120).round().clamp(0, 10000);
    }).then((score) {
      onProgress?.call(1.0);
      return score;
    });
  }

  static Future<int> _storageBenchmark({
    void Function(double progress)? onProgress,
  }) async {
    final directory = await Directory.systemTemp.createTemp('stellar_benchmark_');
    final file = File('${directory.path}/storage_test.bin');
    const size = 8 * 1024 * 1024;
    final buffer = Uint8List(size);
    final random = Random(1234);

    for (var i = 0; i < buffer.length; i += 4096) {
      buffer[i] = random.nextInt(256);
    }

    try {
      final writeWatch = Stopwatch()..start();
      await file.writeAsBytes(buffer, flush: true);
      writeWatch.stop();
      onProgress?.call(0.5);

      final readWatch = Stopwatch()..start();
      final data = await file.readAsBytes();
      readWatch.stop();

      var checksum = 0;
      for (var i = 0; i < data.length; i += 4096) {
        checksum ^= data[i];
      }

      if (checksum < -1) return 0;
      final writeSeconds = max(0.001, writeWatch.elapsedMicroseconds / 1000000.0);
      final readSeconds = max(0.001, readWatch.elapsedMicroseconds / 1000000.0);
      final writeMb = size / 1024 / 1024 / writeSeconds;
      final readMb = size / 1024 / 1024 / readSeconds;
      onProgress?.call(1.0);

      return (sqrt((writeMb + readMb) * 0.5) * 500).round().clamp(0, 10000);
    } finally {
      try {
        if (await file.exists()) await file.delete();
        if (await directory.exists()) await directory.delete();
      } catch (_) {}
    }
  }

  static Future<int> _mixedBenchmark({
    void Function(double progress)? onProgress,
  }) async {
    final result = await Isolate.run(() {
      const size = 4 * 1024 * 1024;
      final buffer = Uint8List(size);
      var value = 0.3141592653;
      var checksum = 0;
      final stopwatch = Stopwatch()..start();

      while (stopwatch.elapsed < const Duration(seconds: 2)) {
        for (var i = 0; i < buffer.length; i += 4096) {
          value = sin(value) * cos(value) + 0.5;
          buffer[i] = ((value.abs() * 255).round()) & 0xff;
          checksum ^= buffer[i];
        }
      }

      stopwatch.stop();
      if (checksum < -1) return 0;
      final work = size / 4096 * max(1, stopwatch.elapsedMilliseconds);
      return (sqrt(work) * 8).round().clamp(0, 10000);
    });

    onProgress?.call(1.0);
    return result;
  }
}
