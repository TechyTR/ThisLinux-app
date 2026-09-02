import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({
    super.key,
  });

  @override
  State<BenchmarkPage> createState() =>
      _BenchmarkPageState();
}

class _BenchmarkPageState
    extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  bool _cancelRequested = false;

  double _progress = 0;

  String _status =
      'Henüz test yapılmadı';

  int _cpuSingle = 0;
  int _cpuMulti = 0;
  int _ramScore = 0;
  int _storageScore = 0;
  int _graphicsScore = 0;
  int _mixedScore = 0;
  int _totalScore = 0;

  late AnimationController
      _graphicsController;

  @override
  void initState() {
    super.initState();

    _graphicsController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _graphicsController.dispose();
    super.dispose();
  }

  Future<void> _startBenchmark() async {
    if (_running) return;

    final confirmed =
        await _showWarning();

    if (!confirmed || !mounted) {
      return;
    }

    _cancelRequested = false;

    setState(() {
      _running = true;
      _progress = 0;
      _status =
          'Benchmark hazırlanıyor...';

      _cpuSingle = 0;
      _cpuMulti = 0;
      _ramScore = 0;
      _storageScore = 0;
      _graphicsScore = 0;
      _mixedScore = 0;
      _totalScore = 0;
    });

    try {
      await _runTests();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _running = false;
        _status =
            'Benchmark sırasında hata oluştu.';
      });
    }
  }

  Future<bool> _showWarning() async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Performans Benchmarkı',
          ),
          content: const Text(
            'Bu test CPU, RAM, depolama ve '
            'grafik birimlerini yoğun şekilde '
            'kullanabilir. Cihaz ısınabilir.\n\n'
            'Android termal korumaları devre '
            'dışı bırakılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text(
                'Başlat',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _runTests() async {
    _setStatus(
      'CPU Single-Core test ediliyor...',
      0.04,
    );

    final single =
        await Isolate.run(
      _cpuSingleWorker,
    );

    if (_shouldStop()) return;

    _setResult(
      () {
        _cpuSingle = single;
      },
      0.18,
    );

    _setStatus(
      'CPU Multi-Core test ediliyor...',
      0.20,
    );

    final multi =
        await _runCpuMulti();

    if (_shouldStop()) return;

    _setResult(
      () {
        _cpuMulti = multi;
      },
      0.38,
    );

    _setStatus(
      'RAM performansı ölçülüyor...',
      0.40,
    );

    final ram =
        await _runRamTest();

    if (_shouldStop()) return;

    _setResult(
      () {
        _ramScore = ram;
      },
      0.53,
    );

    _setStatus(
      'Depolama testi çalışıyor...',
      0.55,
    );

    final storage =
        await _runStorageTest();

    if (_shouldStop()) return;

    _setResult(
      () {
        _storageScore = storage;
      },
      0.70,
    );

    _setStatus(
      'Grafik / UI yükü ölçülüyor...',
      0.72,
    );

    final graphics =
        await _runGraphicsTest();

    if (_shouldStop()) return;

    _setResult(
      () {
        _graphicsScore = graphics;
      },
      0.84,
    );

    _setStatus(
      'Mixed System testi çalışıyor...',
      0.86,
    );

    final mixed =
        await _runMixedTest();

    if (_shouldStop()) return;

    final total =
        _calculateTotal(
      single,
      multi,
      ram,
      storage,
      graphics,
      mixed,
    );

    setState(() {
      _mixedScore = mixed;
      _totalScore = total;
      _progress = 1;
      _status =
          _rating(total);
      _running = false;
    });
  }

  bool _shouldStop() {
    if (!_cancelRequested) {
      return false;
    }

    if (mounted) {
      setState(() {
        _running = false;
        _status =
            'Benchmark iptal edildi.';
      });
    }

    return true;
  }

  void _setStatus(
    String status,
    double progress,
  ) {
    if (!mounted) return;

    setState(() {
      _status = status;
      _progress = progress;
    });
  }

  void _setResult(
    VoidCallback update,
    double progress,
  ) {
    if (!mounted) return;

    setState(() {
      update();
      _progress = progress;
    });
  }

  Future<int> _runCpuMulti() async {
    final cores =
        max(
          2,
          Platform.numberOfProcessors,
        );

    final workers =
        min(8, cores);

    final stopwatch =
        Stopwatch()..start();

    final futures =
        List.generate(
      workers,
      (_) => Isolate.run(
        _cpuMultiWorker,
      ),
    );

    final results =
        await Future.wait(futures);

    stopwatch.stop();

    final operations =
        results.fold<int>(
      0,
      (sum, value) =>
          sum + value,
    );

    final seconds =
        max(
          0.001,
          stopwatch.elapsedMicroseconds /
              1000000,
        );

    final opsPerSecond =
        operations / seconds;

    return _score(
      opsPerSecond,
      30000000,
    );
  }

  static int _cpuSingleWorker() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;

    int iterations = 0;

    while (
        stopwatch.elapsedMilliseconds <
            3000) {
      for (
        var i = 1;
        i < 9000;
        i++
      ) {
        value +=
            sqrt(i) *
            sin(i * 0.17) *
            cos(i * 0.31);

        value =
            value % 1000000;

        iterations++;
      }
    }

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    final seconds =
        max(
          0.001,
          stopwatch.elapsedMicroseconds /
              1000000,
        );

    return _scoreStatic(
      iterations / seconds,
      6000000,
    );
  }

  static int _cpuMultiWorker() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;

    int iterations = 0;

    while (
        stopwatch.elapsedMilliseconds <
            3000) {
      for (
        var i = 1;
        i < 7000;
        i++
      ) {
        value +=
            sqrt(i) *
            sin(i * 0.23) *
            cos(i * 0.41);

        value =
            value % 1000000;

        iterations++;
      }
    }

    if (value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    return iterations;
  }

  Future<int> _runRamTest() async {
    final stopwatch =
        Stopwatch()..start();

    const blockSize =
        16 * 1024 * 1024;

    const blockCount = 24;

    final blocks =
        <Uint8List>[];

    int checksum = 0;

    try {
      for (
        var i = 0;
        i < blockCount;
        i++
      ) {
        final block =
            Uint8List(blockSize);

        for (
          var j = 0;
          j < block.length;
          j += 4096
        ) {
          block[j] =
              (j + i) & 0xff;
        }

        blocks.add(block);
      }

      for (final block in blocks) {
        for (
          var i = 0;
          i < block.length;
          i += 4096
        ) {
          checksum += block[i];
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
        (blockSize *
                blockCount) /
            1024 /
            1024;

    final seconds =
        max(
          0.001,
          stopwatch.elapsedMicroseconds /
              1000000,
        );

    final speed =
        megabytes / seconds;

    return _score(
      speed,
      2500,
    );
  }

  Future<int> _runStorageTest() async {
    Directory? directory;
    File? file;

    try {
      directory =
          await Directory.systemTemp
              .createTemp(
        'stellar_benchmark_',
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

      for (
        var i = 0;
        i < block.length;
        i++
      ) {
        block[i] = i & 0xff;
      }

      final writeTimer =
          Stopwatch()..start();

      final output =
          file.openWrite();

      for (
        var written = 0;
        written < totalSize;
        written += blockSize
      ) {
        output.add(block);
      }

      await output.flush();
      await output.close();

      writeTimer.stop();

      final readTimer =
          Stopwatch()..start();

      int checksum = 0;

      await for (
        final chunk
            in file.openRead()
      ) {
        for (
          var i = 0;
          i < chunk.length;
          i += 8192
        ) {
          checksum += chunk[i];
        }
      }

      readTimer.stop();

      if (checksum == -1) {
        return 1;
      }

      final writeSeconds =
          max(
            0.001,
            writeTimer.elapsedMicroseconds /
                1000000,
          );

      final readSeconds =
          max(
            0.001,
            readTimer.elapsedMicroseconds /
                1000000,
          );

      final writeSpeed =
          128 / writeSeconds;

      final readSpeed =
          128 / readSeconds;

      final combined =
          (writeSpeed +
                  readSpeed) /
              2;

      return _score(
        combined,
        500,
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

  Future<int> _runGraphicsTest() async {
    _graphicsController.repeat();

    final stopwatch =
        Stopwatch()..start();

    int frames = 0;

    while (
        stopwatch.elapsedMilliseconds <
            4000) {
      if (_cancelRequested) {
        _graphicsController.stop();
        return 0;
      }

      await Future.delayed(
        const Duration(
          milliseconds: 16,
        ),
      );

      frames++;
    }

    stopwatch.stop();
    _graphicsController.stop();

    final seconds =
        max(
          0.001,
          stopwatch.elapsedMicroseconds /
              1000000,
        );

    final fps =
        frames / seconds;

    return _score(
      fps,
      60,
    );
  }

  Future<int> _runMixedTest() async {
    final stopwatch =
        Stopwatch()..start();

    final cpuFuture =
        Isolate.run(
      _mixedWorker,
    );

    final memoryFuture =
        _runSmallMemoryLoad();

    final results =
        await Future.wait([
      cpuFuture,
      memoryFuture,
    ]);

    stopwatch.stop();

    final cpu =
        results[0];

    final memory =
        results[1];

    final combined =
        (cpu * 0.65) +
            (memory * 0.35);

    return combined.round();
  }

  static int _mixedWorker() {
    final stopwatch =
        Stopwatch()..start();

    double value = 0;
    int iterations = 0;

    while (
        stopwatch.elapsedMilliseconds <
            2500) {
      for (
        var i = 1;
        i < 10000;
        i++
      ) {
        value +=
            sin(i) *
            cos(i) *
            sqrt(i);

        iterations++;
      }
    }

    if (value.isInfinite ||
        value.isNaN) {
      return 1;
    }

    return _scoreStatic(
      iterations /
          max(
            0.001,
            stopwatch.elapsedMicroseconds /
                1000000,
          ),
      5000000,
    );
  }

  Future<int> _runSmallMemoryLoad() async {
    final blocks =
        <Uint8List>[];

    try {
      for (
        var i = 0;
        i < 10;
        i++
      ) {
        blocks.add(
          Uint8List(
            8 * 1024 * 1024,
          ),
        );
      }

      int value = 0;

      for (final block in blocks) {
        for (
          var i = 0;
          i < block.length;
          i += 8192
        ) {
          value += block[i];
        }
      }

      return min(
        10000,
        max(
          1,
          value + 5000,
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
    return _scoreStatic(
      value,
      baseline,
    );
  }

  static int _scoreStatic(
    double value,
    double baseline,
  ) {
    if (value <= 0 ||
        value.isNaN ||
        value.isInfinite) {
      return 1;
    }

    /*
     * Skor kasıtlı olarak 100 ile
     * sınırlandırılmıyor.
     */
    return max(
      1,
      (value / baseline * 1000)
          .round(),
    );
  }

  int _calculateTotal(
    int single,
    int multi,
    int ram,
    int storage,
    int graphics,
    int mixed,
  ) {
    /*
     * Stellar Center Benchmark skoru:
     *
     * Single  20%
     * Multi   25%
     * RAM     15%
     * Storage 15%
     * GPU/UI  10%
     * Mixed   15%
     *
     * Bu AnTuTu skoru değildir.
     * Stellar'ın kendi performans ölçeğidir.
     */
    return max(
      1,
      (single * 0.20 +
              multi * 0.25 +
              ram * 0.15 +
              storage * 0.15 +
              graphics * 0.10 +
              mixed * 0.15)
          .round(),
    );
  }

  String _rating(int score) {
    if (score >= 30000) {
      return 'Ultra Performans';
    }

    if (score >= 20000) {
      return 'Amiral Gemisi';
    }

    if (score >= 12000) {
      return 'Çok Güçlü';
    }

    if (score >= 7000) {
      return 'Güçlü';
    }

    if (score >= 4000) {
      return 'İyi';
    }

    if (score >= 2000) {
      return 'Orta';
    }

    return 'Temel';
  }

  void _cancelBenchmark() {
    if (!_running) return;

    _cancelRequested = true;
    _graphicsController.stop();

    setState(() {
      _running = false;
      _status =
          'Benchmark iptal edildi.';
    });
  }

  Widget _scoreCard({
    required String title,
    required int score,
    required IconData icon,
  }) {
    final scheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary
                .withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
          ),
        ),
        title: Text(title),
        trailing: Text(
          score == 0
              ? '--'
              : '$score',
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Benchmark',
        ),
        centerTitle: true,
        actions: [
          if (_running)
            IconButton(
              onPressed:
                  _cancelBenchmark,
              icon: const Icon(
                Icons.stop_circle_outlined,
              ),
            ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _totalScore == 0
                        ? '--'
                        : '$_totalScore',
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          scheme.primary,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  const Text(
                    'STELLAR SCORE',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          if (_running) ...[
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child:
                  LinearProgressIndicator(
                minHeight: 9,
                value: _progress,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              '${(_progress * 100).round()}%',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    scheme.primary,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
          ],

          _scoreCard(
            title: 'CPU Single-Core',
            score: _cpuSingle,
            icon: Icons.memory,
          ),

          _scoreCard(
            title: 'CPU Multi-Core',
            score: _cpuMulti,
            icon: Icons.developer_board,
          ),

          _scoreCard(
            title: 'RAM',
            score: _ramScore,
            icon: Icons.sd_storage,
          ),

          _scoreCard(
            title: 'Storage',
            score: _storageScore,
            icon: Icons.storage,
          ),

          _scoreCard(
            title: 'Graphics / UI',
            score: _graphicsScore,
            icon: Icons.graphic_eq,
          ),

          _scoreCard(
            title: 'Mixed System',
            score: _mixedScore,
            icon: Icons.speed,
          ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _running
                  ? null
                  : _startBenchmark,
              icon: Icon(
                _running
                    ? Icons.hourglass_top
                    : Icons.play_arrow,
              ),
              label: Text(
                _running
                    ? 'Test çalışıyor...'
                    : 'Benchmark Başlat',
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'Stellar Score, Stellar Center için '
            'oluşturulmuş bağımsız bir performans '
            'ölçeğidir ve AnTuTu puanıyla aynı değildir.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
