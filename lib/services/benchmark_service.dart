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

  static Future<BenchmarkResult?> run({void Function(String status, double progress)? onProgress}) async {
    _cancelled = false;
    void progress(String status, double value) => onProgress?.call(status, value.clamp(0.0, 1.0));

    try {
      progress('CPU tek çekirdek testi hazırlanıyor...', 0.02);
      final singleCore = await _singleCoreBenchmark();
      if (_cancelled) return null;

      progress('CPU tek çekirdek testi tamamlandı.', 0.20);
      final multiCore = await _multiCoreBenchmark(onProgress: (v) => progress('CPU çoklu çekirdek test ediliyor...', 0.20 + v * 0.23));
      if (_cancelled) return null;

      progress('RAM bant genişliği ölçülüyor...', 0.43);
      final ram = await _ramBenchmark(onProgress: (v) => progress('RAM test ediliyor...', 0.43 + v * 0.14));
      if (_cancelled) return null;

      progress('Depolama performansı ölçülüyor...', 0.57);
      final storage = await _storageBenchmark(onProgress: (v) => progress('Depolama test ediliyor...', 0.57 + v * 0.14));
      if (_cancelled) return null;

      progress('Gerçek 4K 120 FPS grafik testi başlatılıyor...', 0.71);
      final graphicsResult = await BenchmarkGraphicsService.run();
      if (_cancelled) return null;
      final graphics = graphicsResult == null ? 0 : _graphicsScore(graphicsResult);

      progress('10 dakikalık sürdürülebilirlik ve termal testi çalışıyor...', 0.76);
      final mixed = await _mixedBenchmark(onProgress: (v) => progress('Sürdürülebilir CPU + RAM testi...', 0.76 + v * 0.20));
      if (_cancelled) return null;

      progress('Stellar Score hesaplanıyor...', 0.98);
      final total = _calculateTotal(singleCore: singleCore, multiCore: multiCore, ram: ram, storage: storage, graphics: graphics, mixed: mixed);
      progress('Benchmark tamamlandı.', 1.0);
      return BenchmarkResult(singleCore: singleCore, multiCore: multiCore, ram: ram, storage: storage, graphics: graphics, mixed: mixed, total: total, graphicsResult: graphicsResult);
    } catch (_) {
      return null;
    }
  }

  static void cancel() {
    _cancelled = true;
    BenchmarkGraphicsService.cancel();
  }

  static int _calculateTotal({required int singleCore, required int multiCore, required int ram, required int storage, required int graphics, required int mixed}) {
    final score = singleCore * 0.20 + multiCore * 0.25 + ram * 0.15 + storage * 0.15 + graphics * 0.10 + mixed * 0.15;
    return score.round().clamp(0, 10000);
  }

  static int _graphicsScore(GraphicsBenchmarkResult result) {
    if (!result.isValid) return 0;
    const target = 120.0;
    final average = (result.averageFps / target).clamp(0.0, 1.0);
    final low = (result.onePercentLow / target).clamp(0.0, 1.0);
    final minimum = (result.minimumFps / target).clamp(0.0, 1.0);
    final stutter = (1 - result.stutterRate / 100).clamp(0.0, 1.0);
    final processing = result.processingAverageMs <= 0 ? 1.0 : (1 - result.processingAverageMs / 16.67).clamp(0.0, 1.0);
    return ((average * .35 + low * .25 + minimum * .15 + stutter * .15 + processing * .10) * 10000).round().clamp(0, 10000);
  }

  static Future<int> _singleCoreBenchmark() => Isolate.run(_cpuWork);

  static Future<int> _multiCoreBenchmark({void Function(double progress)? onProgress}) async {
    final cores = min(8, max(1, Platform.numberOfProcessors));
    var completed = 0;
    final futures = List<Future<int>>.generate(cores, (_) async {
      final result = await Isolate.run(_cpuWork);
      completed++;
      onProgress?.call(completed / cores);
      return result;
    });
    final results = await Future.wait(futures);
    if (results.isEmpty) return 0;
    return (results.fold<int>(0, (a, b) => a + b) * 1.15).round().clamp(0, 10000);
  }

  static int _cpuWork() {
    final watch = Stopwatch()..start();
    var value = 0.123456789;
    var operations = 0;
    while (watch.elapsed < const Duration(seconds: 2)) {
      value = sin(value) * cos(value) + sqrt(value.abs() + 1.0);
      value -= value.floorToDouble();
      value = sin(value + .37) * .5 + .5;
      operations += 6;
    }
    watch.stop();
    if (value.isNaN || operations <= 0) return 0;
    return (sqrt(operations / max(1, watch.elapsedMicroseconds) * 1000000.0) * 2).round().clamp(0, 10000);
  }

  static Future<int> _ramBenchmark({void Function(double progress)? onProgress}) async {
    return Isolate.run(() {
      const size = 16 * 1024 * 1024;
      const rounds = 6;
      final source = Uint8List(size);
      final destination = Uint8List(size);
      final random = Random(42);
      for (var i = 0; i < source.length; i += 4096) source[i] = random.nextInt(256);
      final watch = Stopwatch()..start();
      var checksum = 0;
      for (var round = 0; round < rounds; round++) {
        destination.setAll(0, source);
        for (var i = 0; i < destination.length; i += 4096) checksum ^= destination[i];
      }
      watch.stop();
      if (checksum < -1) return 0;
      final seconds = max(.001, watch.elapsedMicroseconds / 1000000.0);
      return (sqrt((size * rounds * 2) / 1024 / 1024 / seconds) * 120).round().clamp(0, 10000);
    }).then((score) { onProgress?.call(1); return score; });
  }

  static Future<int> _storageBenchmark({void Function(double progress)? onProgress}) async {
    final directory = await Directory.systemTemp.createTemp('stellar_benchmark_');
    final file = File('${directory.path}/storage_test.bin');
    const size = 8 * 1024 * 1024;
    final buffer = Uint8List(size);
    final random = Random(1234);
    for (var i = 0; i < buffer.length; i += 4096) buffer[i] = random.nextInt(256);
    try {
      final writeWatch = Stopwatch()..start();
      await file.writeAsBytes(buffer, flush: true);
      writeWatch.stop();
      onProgress?.call(.5);
      final readWatch = Stopwatch()..start();
      final data = await file.readAsBytes();
      readWatch.stop();
      var checksum = 0;
      for (var i = 0; i < data.length; i += 4096) checksum ^= data[i];
      if (checksum < -1) return 0;
      final writeMb = size / 1024 / 1024 / max(.001, writeWatch.elapsedMicroseconds / 1000000.0);
      final readMb = size / 1024 / 1024 / max(.001, readWatch.elapsedMicroseconds / 1000000.0);
      onProgress?.call(1);
      return (sqrt((writeMb + readMb) * .5) * 500).round().clamp(0, 10000);
    } finally {
      try { if (await file.exists()) await file.delete(); if (await directory.exists()) await directory.delete(); } catch (_) {}
    }
  }

  static Future<int> _mixedBenchmark({void Function(double progress)? onProgress}) async {
    var checksum = 0;
    var result = 0;
    const chunks = 60;
    for (var chunk = 0; chunk < chunks; chunk++) {
      if (_cancelled) return 0;
      result = await Isolate.run(() => _stressChunk());
      checksum ^= result;
      onProgress?.call((chunk + 1) / chunks);
    }
    if (checksum == -1) return 0;
    return result.clamp(0, 10000);
  }

  static int _stressChunk() {
    const size = 4 * 1024 * 1024;
    final buffer = Uint8List(size);
    var value = .3141592653;
    var checksum = 0;
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 10)) {
      for (var i = 0; i < buffer.length; i += 4096) {
        value = sin(value) * cos(value) + .5;
        buffer[i] = ((value.abs() * 255).round()) & 0xff;
        checksum ^= buffer[i];
      }
    }
    return (sqrt(size / 4096 * max(1, watch.elapsedMilliseconds)) * 8).round() ^ checksum;
  }
}
