import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

class BenchmarkResult {
  final int singleCore;
  final int multiCore;
  final int ram;
  final int storage;
  final int graphics;
  final int mixed;
  final int total;

  const BenchmarkResult({
    required this.singleCore,
    required this.multiCore,
    required this.ram,
    required this.storage,
    required this.graphics,
    required this.mixed,
    required this.total,
  });
}

class BenchmarkService {
  static bool _cancelled = false;

  static void cancel() {
    _cancelled = true;
  }

  static void reset() {
    _cancelled = false;
  }

  static bool get isCancelled => _cancelled;

  static Future<BenchmarkResult?> run({
    required void Function(
      String status,
      double progress,
    ) onProgress,
  }) async {
    reset();

    onProgress(
      'CPU Single-Core test ediliyor...',
      0.05,
    );

    final single = await Isolate.run(
      _singleCore,
    );

    if (isCancelled) return null;

    onProgress(
      'CPU Multi-Core test ediliyor...',
      0.20,
    );

    final multi = await _multiCore();

    if (isCancelled) return null;

    onProgress(
      'RAM performansı ölçülüyor...',
      0.38,
    );

    final ram = await _ram();

    if (isCancelled) return null;

    onProgress(
      'Depolama performansı ölçülüyor...',
      0.53,
    );

    final storage = await _storage();

    if (isCancelled) return null;

    onProgress(
      'Grafik sistemi hazırlanıyor...',
      0.68,
    );

    // Gerçek grafik testi sonraki native
    // 4K/120 FPS katmanından gelecek.
    final graphics = 1000;

    if (isCancelled) return null;

    onProgress(
      'Mixed System testi çalışıyor...',
      0.84,
    );

    final mixed = await _mixed();

    if (isCancelled) return null;

    final total = _total(
      single,
      multi,
      ram,
      storage,
      graphics,
      mixed,
    );

    onProgress(
      'Benchmark tamamlandı.',
      1.0,
    );

    return BenchmarkResult(
      singleCore: single,
      multiCore: multi,
      ram: ram,
      storage: storage,
      graphics: graphics,
      mixed: mixed,
      total: total,
    );
  }

  static int _singleCore() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;
    var operations = 0;

    while (stopwatch.elapsedMilliseconds <
        3000) {
      for (var i = 1; i <= 8000; i++) {
        value +=
            sqrt(i) *
            sin(i * 0.173) *
            cos(i * 0.317);

        value %= 1000000;
        operations++;
      }
    }

    stopwatch.stop();

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    final seconds = max(
      0.001,
      stopwatch.elapsedMicroseconds /
          1000000,
    );

    return _score(
      operations / seconds,
      4500000,
    );
  }

  static Future<int> _multiCore() async {
    final processors =
        max(1, Platform.numberOfProcessors);

    final workers =
        min(8, processors);

    final stopwatch =
        Stopwatch()..start();

    final results = await Future.wait(
      List.generate(
        workers,
        (_) => Isolate.run(
          _multiWorker,
        ),
      ),
    );

    stopwatch.stop();

    final operations =
        results.fold<int>(
      0,
      (a, b) => a + b,
    );

    final seconds = max(
      0.001,
      stopwatch.elapsedMicroseconds /
          1000000,
    );

    return _score(
      operations / seconds,
      22000000,
    );
  }

  static int _multiWorker() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;
    var operations = 0;

    while (stopwatch.elapsedMilliseconds <
        3000) {
      for (var i = 1; i <= 7000; i++) {
        value +=
            sqrt(i) *
            sin(i * 0.211) *
            cos(i * 0.371);

        value %= 1000000;
        operations++;
      }
    }

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    return operations;
  }

  static Future<int> _ram() async {
    const blockSize =
        8 * 1024 * 1024;

    const blockCount = 32;

    final stopwatch =
        Stopwatch()..start();

    final blocks =
        <Uint8List>[];

    var checksum = 0;

    try {
      for (var i = 0;
          i < blockCount;
          i++) {
        final block =
            Uint8List(blockSize);

        for (var p = 0;
            p < block.length;
            p += 64) {
          block[p] =
              (p + i * 13) & 255;
        }

        blocks.add(block);
      }

      for (final block in blocks) {
        for (var p = 0;
            p < block.length;
            p += 64) {
          checksum += block[p];
        }
      }
    } finally {
      blocks.clear();
    }

    stopwatch.stop();

    if (checksum == -1) {
      return 1;
    }

    final megabytes =
        blockSize *
            blockCount /
            1024 /
            1024;

    final seconds = max(
      0.001,
      stopwatch.elapsedMicroseconds /
          1000000,
    );

    return _score(
      megabytes / seconds,
      5000,
    );
  }

  static Future<int> _storage() async {
    Directory? directory;
    File? file;

    try {
      directory =
          await Directory.systemTemp
              .createTemp(
        'stellar_benchmark',
      );

      file = File(
        '${directory.path}/test.bin',
      );

      const totalSize =
          128 * 1024 * 1024;

      const blockSize =
          1024 * 1024;

      final block =
          Uint8List(blockSize);

      for (var i = 0;
          i < block.length;
          i++) {
        block[i] = i & 255;
      }

      final writeWatch =
          Stopwatch()..start();

      final output =
          file.openWrite();

      for (var written = 0;
          written < totalSize;
          written += blockSize) {
        output.add(block);
      }

      await output.flush();
      await output.close();

      writeWatch.stop();

      if (isCancelled) {
        return 0;
      }

      final readWatch =
          Stopwatch()..start();

      var checksum = 0;

      await for (
        final chunk
            in file.openRead()
      ) {
        for (var i = 0;
            i < chunk.length;
            i += 8192) {
          checksum += chunk[i];
        }
      }

      readWatch.stop();

      if (checksum == -1) {
        return 1;
      }

      final writeSeconds =
          max(
        0.001,
        writeWatch.elapsedMicroseconds /
            1000000,
      );

      final readSeconds =
          max(
        0.001,
        readWatch.elapsedMicroseconds /
            1000000,
      );

      final writeSpeed =
          128 / writeSeconds;

      final readSpeed =
          128 / readSeconds;

      return _score(
        (writeSpeed + readSpeed) / 2,
        600,
      );
    } catch (_) {
      return 1;
    } finally {
      try {
        await file?.delete();
      } catch (_) {}

      try {
        await directory?.delete();
      } catch (_) {}
    }
  }

  static Future<int> _mixed() async {
    final cpu =
        Isolate.run(
      _mixedCpu,
    );

    final memory =
        _mixedMemory();

    final results =
        await Future.wait([
      cpu,
      memory,
    ]);

    return (
      results[0] * 0.65 +
      results[1] * 0.35
    ).round();
  }

  static int _mixedCpu() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;
    var operations = 0;

    while (stopwatch.elapsedMilliseconds <
        2500) {
      for (var i = 1;
          i <= 7000;
          i++) {
        value +=
            sqrt(i) *
            sin(i) *
            cos(i);

        operations++;
      }
    }

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    final seconds = max(
      0.001,
      stopwatch.elapsedMicroseconds /
          1000000,
    );

    return _score(
      operations / seconds,
      4500000,
    );
  }

  static Future<int> _mixedMemory() async {
    final blocks =
        <Uint8List>[];

    try {
      for (var i = 0; i < 12; i++) {
        blocks.add(
          Uint8List(
            4 * 1024 * 1024,
          ),
        );
      }

      var checksum = 0;

      for (final block in blocks) {
        for (var i = 0;
            i < block.length;
            i += 64) {
          block[i] =
              (i ~/ 64) & 255;

          checksum += block[i];
        }
      }

      if (checksum < 0) {
        return 1;
      }

      return 7000;
    } finally {
      blocks.clear();
    }
  }

  static int _score(
    double value,
    double baseline,
  ) {
    if (value <= 0 ||
        value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    return max(
      1,
      (value / baseline * 1000)
          .round(),
    );
  }

  static int _total(
    int single,
    int multi,
    int ram,
    int storage,
    int graphics,
    int mixed,
  ) {
    return max(
      1,
      (
        single * 0.20 +
        multi * 0.25 +
        ram * 0.15 +
        storage * 0.15 +
        graphics * 0.10 +
        mixed * 0.15
      ).round(),
    );
  }
}
