import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() =>
      _BenchmarkPageState();
}

class _BenchmarkPageState
    extends State<BenchmarkPage> {
  bool _running = false;
  double _progress = 0;

  int _cpuScore = 0;
  int _memoryScore = 0;
  int _storageScore = 0;
  int _totalScore = 0;

  String _status = 'Henüz test yapılmadı';

  Future<void> _startBenchmark() async {
    if (_running) return;

    final shouldContinue =
        await _showWarningDialog();

    if (!shouldContinue || !mounted) {
      return;
    }

    await _runBenchmark();
  }

  Future<bool> _showWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Performans Testi',
          ),
          content: const Text(
            'Cihazınız performans testi sırasında '
            'ısınabilir.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Devam Et',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _runBenchmark() async {
    if (_running) return;

    setState(() {
      _running = true;
      _progress = 0;
      _cpuScore = 0;
      _memoryScore = 0;
      _storageScore = 0;
      _totalScore = 0;
      _status = 'CPU testi çalışıyor...';
    });

    final cpuScore =
        await _runCpuTest();

    if (!mounted) return;

    setState(() {
      _cpuScore = cpuScore;
      _progress = 0.35;
      _status = 'Bellek testi çalışıyor...';
    });

    final memoryScore =
        await _runMemoryTest();

    if (!mounted) return;

    setState(() {
      _memoryScore = memoryScore;
      _progress = 0.65;
      _status =
          'Depolama okuma/yazma testi çalışıyor...';
    });

    final storageScore =
        await _runStorageTest();

    if (!mounted) return;

    final total = max(
      1,
      ((_cpuScore * 0.50) +
              (_memoryScore * 0.25) +
              (storageScore * 0.25))
          .round(),
    );

    setState(() {
      _storageScore = storageScore;
      _totalScore = total;
      _progress = 1;
      _status = _getRating(total);
      _running = false;
    });
  }

  Future<int> _runCpuTest() async {
    final stopwatch = Stopwatch()..start();

    double result = 0;

    while (stopwatch.elapsedMilliseconds < 1800) {
      for (var i = 1; i < 12000; i++) {
        result +=
            sqrt(i) *
            sin(i) *
            cos(i);
      }
    }

    stopwatch.stop();

    if (result.isNaN ||
        result.isInfinite) {
      return 1;
    }

    final elapsed =
        max(
          1,
          stopwatch.elapsedMicroseconds,
        );

    final operations =
        2160000000 ~/ elapsed;

    return min(
      100,
      max(
        1,
        operations ~/ 5,
      ),
    );
  }

  Future<int> _runMemoryTest() async {
    final stopwatch = Stopwatch()..start();

    final blocks = <List<int>>[];

    try {
      for (var i = 0; i < 12; i++) {
        blocks.add(
          List<int>.filled(
            250000,
            i,
            growable: false,
          ),
        );
      }

      var checksum = 0;

      for (final block in blocks) {
        for (
          var i = 0;
          i < block.length;
          i += 256
        ) {
          checksum += block[i];
        }
      }

      if (checksum == -1) {
        return 1;
      }
    } finally {
      blocks.clear();
    }

    stopwatch.stop();

    final elapsed =
        max(
          1,
          stopwatch.elapsedMilliseconds,
        );

    final score =
        100 - (elapsed ~/ 12);

    return min(
      100,
      max(
        1,
        score,
      ),
    );
  }

  Future<int> _runStorageTest() async {
    final stopwatch = Stopwatch()..start();

    File? testFile;

    try {
      /*
       * Uygulamanın cache klasöründe
       * geçici benchmark dosyası oluşturulur.
       *
       * Böylece depolama benchmark'ı için
       * harici depolama izni gerekmez.
       */

      final directory =
          await Directory.systemTemp.createTemp(
        'thislinux_storage_benchmark_',
      );

      testFile = File(
        '${directory.path}/storage_test.bin',
      );

      /*
       * 8 MB test verisi.
       *
       * Büyük ama kısa süreli bir I/O testi
       * oluşturmak için kullanılır.
       */
      const blockSize = 1024 * 1024;
      const blockCount = 8;

      final block = List<int>.generate(
        blockSize,
        (index) => index % 256,
      );

      /*
       * YAZMA TESTİ
       */
      final writeStopwatch =
          Stopwatch()..start();

      final output =
          testFile.openWrite();

      for (var i = 0;
          i < blockCount;
          i++) {
        output.add(block);
      }

      await output.flush();
      await output.close();

      writeStopwatch.stop();

      /*
       * OKUMA TESTİ
       */
      final readStopwatch =
          Stopwatch()..start();

      var checksum = 0;

      final input =
          testFile.openRead();

      await for (final chunk in input) {
        for (
          var i = 0;
          i < chunk.length;
          i += 4096
        ) {
          checksum += chunk[i];
        }
      }

      readStopwatch.stop();

      if (checksum == -1) {
        return 1;
      }

      stopwatch.stop();

      /*
       * Toplam 8 MB yazıldı ve 8 MB okundu.
       */
      const totalMegabytes = 16.0;

      final totalSeconds =
          stopwatch.elapsedMicroseconds /
              1000000.0;

      final totalSpeed =
          totalMegabytes /
              max(
                0.001,
                totalSeconds,
              );

      /*
       * Yaklaşık 50 MB/s ve üzerini
       * 100 puan civarına yaklaştırır.
       *
       * Bu değer cihazlar arasında
       * karşılaştırma yapılabilmesi için
       * normalize edilir.
       */
      final score =
          (totalSpeed * 2).round();

      return min(
        100,
        max(
          1,
          score,
        ),
      );
    } catch (_) {
      return 1;
    } finally {
      try {
        await testFile?.delete();

        final parent =
            testFile?.parent;

        if (parent != null &&
            await parent.exists()) {
          await parent.delete();
        }
      } catch (_) {}
    }
  }

  String _getRating(int score) {
    if (score >= 90) {
      return 'Amiral Gemisi';
    }

    if (score >= 75) {
      return 'Harika';
    }

    if (score >= 60) {
      return 'İyi';
    }

    if (score >= 45) {
      return 'Orta';
    }

    if (score >= 25) {
      return 'Biraz Kötü';
    }

    return 'Kötü';
  }

  Widget _scoreCard(
    String title,
    int score,
    IconData icon,
  ) {
    final color =
        Theme.of(context)
            .colorScheme
            .primary;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(title),
        trailing: Text(
          '$score/100',
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
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Benchmark',
        ),
        centerTitle: true,
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
                      fontSize: 64,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          scheme.primary,
                    ),
                  ),
                  const Text(
                    'Genel Performans',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          if (_running)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(_status),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),

          _scoreCard(
            'CPU',
            _cpuScore,
            Icons.memory,
          ),

          _scoreCard(
            'Bellek',
            _memoryScore,
            Icons.memory,
          ),

          _scoreCard(
            'Depolama',
            _storageScore,
            Icons.storage,
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            height: 54,
            child:
                FilledButton.icon(
              onPressed:
                  _running
                      ? null
                      : _startBenchmark,
              icon: const Icon(
                Icons.speed,
              ),
              label: Text(
                _running
                    ? 'Test çalışıyor...'
                    : 'Benchmark Başlat',
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            'Performans testi cihazı kısa süreliğine '
            'yüksek işlem altında çalıştırabilir.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
