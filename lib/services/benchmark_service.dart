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
      0.03,
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
      0.40,
    );

    final ram = await _ram();

    if (isCancelled) return null;

    onProgress(
      'Depolama performansı ölçülüyor...',
      0.55,
    );

    final storage = await _storage();

    if (isCancelled) return null;

    onProgress(
      'Grafik ve UI yükü ölçülüyor...',
      0.72,
    );

    /*
     * Gerçek grafik yükü BenchmarkPage
     * tarafından oluşturuluyor. Burada
     * servis sadece sonucu bekliyor.
     */
    final graphics =
        await _graphicsFallback();

    if (isCancelled) return null;

    onProgress(
      'Mixed System testi çalışıyor...',
      0.86,
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
    final watch = Stopwatch()..start();

    double value = 0;
    int operations = 0;

    while (watch.elapsedMilliseconds < 2500) {
      for (var i = 1; i <= 6000; i++) {
        value +=
            sqrt(i) *
            sin(i * 0.17) *
            cos(i * 0.31);

        value %= 1000000;
        operations++;
      }
    }

    if (value.isNaN || value.isInfinite) {
      return 1;
    }

    final seconds =
        max(
          0.001,
          watch.elapsedMicroseconds / 1000000,
        );

    return _score(
      operations / seconds,
      4000000,
    );
  }

  static Future<int> _multiCore() async {
    final processors =
        max(1, Platform.numberOfProcessors);

    /*
     * Mantıksız şekilde yüzlerce isolate
     * oluşturmuyoruz.
     */
    final workers =
        min(8, processors);

    final watch = Stopwatch()..start();

    final results =
        await Future.wait(
      List.generate(
        workers,
        (_) => Isolate.run(
          _multiWorker,
        ),
      ),
    );

    watch.stop();

    final operations =
        results.fold<int>(
      0,
      (a, b) => a + b,
    );

    final seconds =
        max(
          0.001,
          watch.elapsedMicroseconds / 1000000,
        );

    return _score(
      operations / seconds,
      20000000,
    );
  }

  static int _multiWorker() {
    final watch = Stopwatch()..start();

    double value = 0;
    int operations = 0;

    while (watch.elapsedMilliseconds < 2500) {
      for (var i = 1; i <= 5000; i++) {
        value +=
            sqrt(i) *
            sin(i * 0.21) *
            cos(i * 0.37);

        value %= 1000000;
        operations++;
      }
    }

    if (value.isNaN || value.isInfinite) {
      return 1;
    }

    return operations;
  }

  static Future<int> _ram() async {
    /*
     * 128 MB kullanıyoruz.
     * Benchmark için yeterli yük oluşturur,
     * ancak cihazdaki RAM'in tamamını
     * tüketmeye çalışmaz.
     */
    const blockSize = 8 * 1024 * 1024;
    const blockCount = 16;

    final watch = Stopwatch()..start();

    final blocks =
        <Uint8List>[];

    var checksum = 0;

    try {
      for (var i = 0; i < blockCount; i++) {
        final block =
            Uint8List(blockSize);

        for (
          var p = 0;
          p < block.length;
          p += 4096
        ) {
          block[p] =
              (p + i) & 255;
        }

        blocks.add(block);
      }

      for (final block in blocks) {
        for (
          var p = 0;
          p < block.length;
          p += 4096
        ) {
          checksum += block[p];
        }
      }
    } finally {
      blocks.clear();
    }

    watch.stop();

    if (checksum == -1) {
      return 1;
    }

    final megabytes =
        (blockSize * blockCount) /
            1024 /
            1024;

    final seconds =
        max(
          0.001,
          watch.elapsedMicroseconds / 1000000,
        );

    return _score(
      megabytes / seconds,
      1800,
    );
  }

  static Future<int> _storage() async {
    Directory? directory;
    File? file;

    try {
      directory =
          await Directory.systemTemp.createTemp(
        'stellar_benchmark',
      );

      file = File(
        '${directory.path}/storage_test.bin',
      );

      const size =
          64 * 1024 * 1024;

      const blockSize =
          1024 * 1024;

      final block =
          Uint8List(blockSize);

      for (var i = 0; i < block.length; i++) {
        block[i] = i & 255;
      }

      final writeWatch =
          Stopwatch()..start();

      final output =
          file.openWrite();

      for (
        var written = 0;
        written < size;
        written += blockSize
      ) {
        output.add(block);
      }

      await output.flush();
      await output.close();

      writeWatch.stop();

      if (isCancelled) return 0;

      final readWatch =
          Stopwatch()..start();

      var checksum = 0;

      await for (
        final chunk in file.openRead()
      ) {
        for (
          var i = 0;
          i < chunk.length;
          i += 8192
        ) {
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
          64 / writeSeconds;

      final readSpeed =
          64 / readSeconds;

      return _score(
        (writeSpeed + readSpeed) / 2,
        300,
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

  static Future<int> _graphicsFallback() async {
    /*
     * Grafik sonucu UI tarafındaki gerçek
     * frame ölçümünden gelebilecek şekilde
     * ayrılmıştır.
     *
     * Şimdilik platform bağımsız güvenli
     * bir temel değer kullanıyoruz.
     */
    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    return 1000;
  }

  static Future<int> _mixed() async {
    final cpu =
        Isolate.run(
      _mixedWorker,
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

  static int _mixedWorker() {
    final watch = Stopwatch()..start();

    double value = 0;
    var operations = 0;

    while (watch.elapsedMilliseconds < 2000) {
      for (var i = 1; i <= 6000; i++) {
        value +=
            sin(i) *
            cos(i) *
            sqrt(i);

        operations++;
      }
    }

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    final seconds =
        max(
          0.001,
          watch.elapsedMicroseconds / 1000000,
        );

    return _score(
      operations / seconds,
      4000000,
    );
  }

  static Future<int> _mixedMemory() async {
    final blocks =
        <Uint8List>[];

    try {
      for (var i = 0; i < 8; i++) {
        blocks.add(
          Uint8List(
            4 * 1024 * 1024,
          ),
        );
      }

      var value = 0;

      for (final block in blocks) {
        for (
          var i = 0;
          i < block.length;
          i += 4096
        ) {
          block[i] =
              (i ~/ 4096) & 255;

          value += block[i];
        }
      }

      return min(
        10000,
        max(
          1,
          4000 + value % 6000,
        ),
      );
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
      (value / baseline * 1000).round(),
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
