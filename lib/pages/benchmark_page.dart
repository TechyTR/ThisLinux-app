lib/pages/benchmark_page.dart dosyasını tamamen aşağıdaki kodla değiştir:
import 'package:flutter/material.dart';

import '../services/benchmark_service.dart';

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
  double _progress = 0;
  String _status = 'Hazır';
  BenchmarkResult? _result;

  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Benchmark'),
          content: const Text(
            'Bu test cihazın CPU, RAM ve depolama '
            'birimlerini yoğun şekilde kullanabilir. '
            'Cihaz ısınabilir.\n\n'
            'Android termal korumaları devre dışı bırakılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('Başlat'),
            ),
          ],
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    setState(() {
      _running = true;
      _progress = 0;
      _status = 'Benchmark hazırlanıyor...';
      _result = null;
    });

    _animation.repeat();

    final result = await BenchmarkService.run(
      onProgress: (status, progress) {
        if (!mounted) return;

        setState(() {
          _status = status;
          _progress = progress;
        });
      },
    );

    _animation.stop();

    if (!mounted) return;

    setState(() {
      _running = false;
      _result = result;

      if (result == null) {
        _status = 'Benchmark iptal edildi.';
      } else {
        _status = _rating(result.total);
      }
    });
  }

  void _cancel() {
    if (!_running) return;

    BenchmarkService.cancel();

    setState(() {
      _status = 'Benchmark durduruluyor...';
    });
  }

  String _rating(int score) {
    if (score >= 30000) return 'Ultra Performans';
    if (score >= 20000) return 'Amiral Gemisi';
    if (score >= 12000) return 'Çok Güçlü';
    if (score >= 7000) return 'Güçlü';
    if (score >= 4000) return 'İyi';
    if (score >= 2000) return 'Orta';

    return 'Temel';
  }

  Widget _scoreCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int? value,
  }) {
    final color =
        Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(title),
        trailing: Text(
          value == null ? '--' : '$value',
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

    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
        centerTitle: true,
        actions: [
          if (_running)
            IconButton(
              onPressed: _cancel,
              icon: const Icon(
                Icons.stop_circle_outlined,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            _animation.value * 6.28,
                        child: Icon(
                          _running
                              ? Icons.auto_awesome
                              : Icons.speed,
                          size: 42,
                          color: scheme.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    result == null
                        ? '--'
                        : '${result.total}',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const Text(
                    'STELLAR SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_running) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: _progress,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          const SizedBox(height: 18),

          _scoreCard(
            context,
            icon: Icons.memory,
            title: 'CPU Single-Core',
            value: result?.singleCore,
          ),

          _scoreCard(
            context,
            icon: Icons.developer_board,
            title: 'CPU Multi-Core',
            value: result?.multiCore,
          ),

          _scoreCard(
            context,
            icon: Icons.sd_storage,
            title: 'RAM',
            value: result?.ram,
          ),

          _scoreCard(
            context,
            icon: Icons.storage,
            title: 'Storage',
            value: result?.storage,
          ),

          _scoreCard(
            context,
            icon: Icons.graphic_eq,
            title: 'Graphics / UI',
            value: result?.graphics,
          ),

          _scoreCard(
            context,
            icon: Icons.speed,
            title: 'Mixed System',
            value: result?.mixed,
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  _running ? null : _start,
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

          const SizedBox(height: 14),

          Text(
            'Stellar Score, Stellar Center '
            'için kullanılan bağımsız bir '
            'performans ölçeğidir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

