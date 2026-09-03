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

  late final AnimationController
      _animation;

  @override
  void initState() {
    super.initState();

    _animation =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;

    final accepted =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Stellar Benchmark',
          ),
          content: const Text(
            'Benchmark cihazın CPU, RAM ve depolama birimlerini yoğun şekilde kullanır.\n\n'
            'Cihaz ısınabilir ve pil tüketimi artabilir.\n\n'
            'Android termal korumaları devre dışı bırakılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('İptal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Başlat'),
            ),
          ],
        );
      },
    );

    if (accepted != true ||
        !mounted) {
      return;
    }

    setState(() {
      _running = true;
      _progress = 0;
      _status =
          'Benchmark hazırlanıyor...';
      _result = null;
    });

    _animation.repeat();

    final result =
        await BenchmarkService.run(
      onProgress:
          (status, progress) {
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
        _status =
            'Benchmark iptal edildi.';
      } else {
        _status =
            _rating(result.total);
      }
    });
  }

  void _cancel() {
    if (!_running) return;

    BenchmarkService.cancel();

    setState(() {
      _status =
          'Benchmark durduruluyor...';
    });
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

  Widget _scoreCard({
    required IconData icon,
    required String title,
    required int? value,
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary
                .withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
          ),
        ),
        title: Text(title),
        trailing: Text(
          value == null
              ? '--'
              : '$value',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
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

    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Benchmark',
        ),
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
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                25,
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation:
                        _animation,
                    builder:
                        (context, child) {
                      return Transform
                          .rotate(
                        angle:
                            _animation.value *
                                6.283185,
                        child: Icon(
                          _running
                              ? Icons.auto_awesome_rounded
                              : Icons.speed_rounded,
                          size: 46,
                          color:
                              scheme.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Text(
                    result == null
                        ? '--'
                        : '${result.total}',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          scheme.primary,
                    ),
                  ),
                  const Text(
                    'STELLAR SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_running) ...[
            const SizedBox(
              height: 14,
            ),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              child:
                  LinearProgressIndicator(
                minHeight: 8,
                value: _progress,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '${(_progress * 100).round()}%',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    scheme.primary,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],

          const SizedBox(
            height: 20,
          ),

          _scoreCard(
            icon:
                Icons.memory_rounded,
            title:
                'CPU Single-Core',
            value:
                result?.singleCore,
          ),

          _scoreCard(
            icon:
                Icons.developer_board_rounded,
            title:
                'CPU Multi-Core',
            value:
                result?.multiCore,
          ),

          _scoreCard(
            icon:
                Icons.sd_storage_rounded,
            title: 'RAM',
            value: result?.ram,
          ),

          _scoreCard(
            icon:
                Icons.storage_rounded,
            title: 'Storage',
            value:
                result?.storage,
          ),

          _scoreCard(
            icon:
                Icons.graphic_eq_rounded,
            title:
                'Graphics / UI',
            value:
                result?.graphics,
          ),

          _scoreCard(
            icon:
                Icons.speed_rounded,
            title:
                'Mixed System',
            value:
                result?.mixed,
          ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            height: 55,
            child:
                FilledButton.icon(
              onPressed:
                  _running
                      ? null
                      : _start,
              icon: Icon(
                _running
                    ? Icons.hourglass_top_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                _running
                    ? 'Test çalışıyor...'
                    : 'Benchmark Başlat',
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            'Graphics / UI sonucu gerçek 4K 120 FPS video testine geçildiğinde native frame ölçümleriyle hesaplanacaktır.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: scheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
