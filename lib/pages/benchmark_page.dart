import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() =>
      _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  bool _running = false;
  double _progress = 0;

  int _cpuScore = 0;
  int _memoryScore = 0;
  int _storageScore = 0;
  int _totalScore = 0;

  String _rating = 'Henüz test yapılmadı';

  Future<void> _runBenchmark() async {
    if (_running) return;

    setState(() {
      _running = true;
      _progress = 0;
      _cpuScore = 0;
      _memoryScore = 0;
      _storageScore = 0;
      _totalScore = 0;
      _rating = 'Test hazırlanıyor...';
    });

    final cpuScore = await _runCpuTest();

    if (!mounted) return;

    setState(() {
      _cpuScore = cpuScore;
      _progress = 0.35;
      _rating = 'CPU testi tamamlandı';
    });

    final memoryScore = await _runMemoryTest();

    if (!mounted) return;

    setState(() {
      _memoryScore = memoryScore;
      _progress = 0.65;
      _rating = 'Bellek testi tamamlandı';
    });

    final storageScore = await _runStorageTest();

    if (!mounted) return;

    final total = max(
      1,
      ((_cpuScore * 0.50) +
              (_memoryScore * 0.25) +
              (_storageScore * 0.25))
          .round(),
    );

    setState(() {
      _storageScore = storageScore;
      _totalScore = total;
      _progress = 1;
      _rating = _getRating(total);
      _running = false;
    });
  }

  Future<int> _runCpuTest() async {
    final stopwatch = Stopwatch()..start();

    double result = 0;

    while (stopwatch.elapsedMilliseconds < 900) {
      for (int i = 1; i < 10000; i++) {
        result += sqrt(i) * sin(i);
      }
    }

    stopwatch.stop();

    if (result == double.infinity) {
      return 1;
    }

    final operations =
        900000000 ~/ max(
          1,
          stopwatch.elapsedMicroseconds,
        );

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

    final List<List<int>> blocks = [];

    try {
      for (int i = 0; i < 8; i++) {
        blocks.add(
          List<int>.filled(
            250000,
            i,
            growable: false,
          ),
        );
      }

      for (final block in blocks) {
        for (int i = 0;
            i < block.length;
            i += 1000) {
          block[i] = block[i] + 1;
        }
      }
    } finally {
      blocks.clear();
    }

    stopwatch.stop();

    final score =
        100 -
        (stopwatch.elapsedMilliseconds ~/ 20);

    return min(
      100,
      max(
        1,
        score,
      ),
    );
  }

  Future<int> _runStorageTest() async {
    final directory =
        Directory('/data/data');

    final stopwatch = Stopwatch()..start();

    try {
      await directory.exists();
    } catch (_) {}

    stopwatch.stop();

    final score =
        100 -
        stopwatch.elapsedMilliseconds;

    return min(
      100,
      max(
        1,
        score,
      ),
    );
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
        Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(title),
        trailing: Text(
          '$score/100',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _totalScore == 0
                        ? '--'
                        : '$_totalScore',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const Text(
                    'Genel Performans',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rating,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_running)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                ),
                const SizedBox(height: 10),
                Text(_rating),
                const SizedBox(height: 16),
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

          const SizedBox(height: 12),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  _running ? null : _runBenchmark,
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

          const SizedBox(height: 16),

          Text(
            'Test sırasında cihazın normalden fazla işlem yapması '
            've kısa süreli ısınması normaldir.',
            textAlign: TextAlign.center,
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
