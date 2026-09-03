import 'package:flutter/material.dart';

import '../services/benchmark_graphics_service.dart';
import '../services/benchmark_service.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({
    super.key,
  });

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState
    extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  double _progress = 0;
  String _status = 'Hazır';

  BenchmarkResult? _result;
  double? _displayRefreshRate;

  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _loadDisplayRefreshRate();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayRefreshRate() async {
    final rate =
        await BenchmarkGraphicsService.getDisplayRefreshRate();

    if (!mounted) return;

    setState(() {
      _displayRefreshRate = rate;
    });
  }

  Future<void> _start() async {
    if (_running) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Stellar Benchmark',
          ),
          content: const Text(
            'Benchmark cihazın CPU, RAM, depolama ve grafik sistemini yoğun şekilde kullanır.\n\n'
            'Cihaz ısınabilir ve pil tüketimi artabilir.\n\n'
            '4K 120 FPS video testi sırasında cihazın donanımsal video decoder performansı da ölçülür.\n\n'
            'Android termal korumaları devre dışı bırakılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Başlat',
              ),
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

    await _loadDisplayRefreshRate();

    if (!mounted) return;

    setState(() {
      _running = false;
      _result = result;

      if (result == null) {
        _status = 'Benchmark iptal edildi.';
      } else {
        _status = _rating(
          result.total,
        );
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
    if (score >= 9000) {
      return 'Ultra Performans';
    }

    if (score >= 7500) {
      return 'Amiral Gemisi';
    }

    if (score >= 6000) {
      return 'Çok Güçlü';
    }

    if (score >= 4500) {
      return 'Güçlü';
    }

    if (score >= 3000) {
      return 'İyi';
    }

    if (score >= 1500) {
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
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(
              0.12,
            ),
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
        title: Text(
          title,
        ),
        trailing: Text(
          value == null
              ? '--'
              : '$value',
          style: const TextStyle(
            fontWeight:
                FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _graphicsCard(
    GraphicsBenchmarkResult? graphics,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    if (graphics == null) {
      return Card(
        margin: const EdgeInsets.only(
          top: 12,
          bottom: 9,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons
                    .error_outline_rounded,
                color: scheme.error,
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  '4K 120 FPS grafik testi çalıştırılamadı.',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final valid = graphics.isValid;

    return Card(
      margin: const EdgeInsets.only(
        top: 12,
        bottom: 9,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color: scheme.primary
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .movie_filter_rounded,
                    color:
                        scheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Expanded(
                  child: Text(
                    '4K 120 FPS Video',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  valid
                      ? Icons
                          .check_circle_rounded
                      : Icons
                          .warning_rounded,
                  color: valid
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            _detailRow(
              'Çözünürlük',
              '${graphics.videoWidth} × ${graphics.videoHeight}',
            ),
            _detailRow(
              'Kaynak FPS',
              '${graphics.videoFps.toStringAsFixed(1)} FPS',
            ),
            _detailRow(
              'Ortalama FPS',
              '${graphics.averageFps.toStringAsFixed(1)} FPS',
            ),
            _detailRow(
              'Minimum FPS',
              '${graphics.minimumFps.toStringAsFixed(1)} FPS',
            ),
            _detailRow(
              '1% Low',
              '${graphics.onePercentLow.toStringAsFixed(1)} FPS',
            ),
            _detailRow(
              'Frame Time',
              '${graphics.frameTimeMs.toStringAsFixed(2)} ms',
            ),
            _detailRow(
              'Dropped Frames',
              '${graphics.droppedFrames}',
            ),
            _detailRow(
              'Rendered Frames',
              '${graphics.renderedFrames}',
            ),
            _detailRow(
              'Stutter',
              '${graphics.stutterRate.toStringAsFixed(2)}%',
            ),
            _detailRow(
              'Decoder Processing',
              '${graphics.processingAverageMs.toStringAsFixed(2)} ms',
            ),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color:
                  scheme.outlineVariant,
            ),
            const SizedBox(
              height: 8,
            ),
            _detailRow(
              'Ekran Yenileme Hızı',
              _displayRefreshRate == null
                  ? '--'
                  : '${_displayRefreshRate!.toStringAsFixed(1)} Hz',
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Ekranın yenileme hızı video decoder testinden ayrı değerlendirilir. '
              'Örneğin 60 Hz ekran, 120 FPS kaynağın tamamını fiziksel olarak gösteremez; '
              'ancak cihazın decoder performansı yine ölçülebilir.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color:
                    scheme.onSurfaceVariant,
              ),
            ),
          ],
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
                Icons
                    .stop_circle_outlined,
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
                      return Transform.rotate(
                        angle:
                            _animation.value *
                                6.283185,
                        child: Icon(
                          _running
                              ? Icons
                                  .auto_awesome_rounded
                              : Icons
                                  .speed_rounded,
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
            value:
                result?.ram,
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
                'Graphics / Video',
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

          if (result != null)
            _graphicsCard(
              result.graphicsResult,
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
                    ? Icons
                        .hourglass_top_rounded
                    : Icons
                        .play_arrow_rounded,
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
            'Stellar Benchmark; CPU, RAM, depolama, grafik/video decoder ve karma sistem yükünü ölçer.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
