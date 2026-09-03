import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/benchmark_graphics_service.dart';
import '../services/benchmark_service.dart';

class _TelemetryPoint {
  final Duration elapsed;
  final BenchmarkTelemetry value;

  const _TelemetryPoint(this.elapsed, this.value);
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  bool _readingTelemetry = false;
  double _progress = 0;
  String _status = 'Hazır';
  BenchmarkResult? _result;
  double? _displayRefreshRate;
  DateTime? _startedAt;
  Timer? _telemetryTimer;
  final List<_TelemetryPoint> _telemetry = [];
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
    _telemetryTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayRefreshRate() async {
    final rate = await BenchmarkGraphicsService.getDisplayRefreshRate();
    if (mounted) setState(() => _displayRefreshRate = rate);
  }

  Future<void> _captureTelemetry() async {
    if (_readingTelemetry || _startedAt == null) return;
    _readingTelemetry = true;
    final reading = await BenchmarkGraphicsService.readTelemetry();
    _readingTelemetry = false;
    if (!mounted || _startedAt == null) return;
    setState(() {
      _telemetry.add(
        _TelemetryPoint(DateTime.now().difference(_startedAt!), reading),
      );
    });
  }

  Future<void> _start() async {
    if (_running) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stellar Benchmark'),
        content: const Text(
          'CPU, RAM, depolama ve 4K 120 FPS video decoder testi çalıştırılır. '
          'Cihaz ısınabilir ve pil tüketimi artabilir. Android termal korumaları değiştirilmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    setState(() {
      _running = true;
      _progress = 0;
      _status = 'Benchmark hazırlanıyor...';
      _result = null;
      _telemetry.clear();
      _startedAt = DateTime.now();
    });
    await _captureTelemetry();
    _telemetryTimer = Timer.periodic(
      const Duration(milliseconds: 750),
      (_) => _captureTelemetry(),
    );
    _animation.repeat();

    final result = await BenchmarkService.run(
      onProgress: (status, progress) {
        if (mounted) setState(() {
          _status = status;
          _progress = progress;
        });
      },
    );

    _telemetryTimer?.cancel();
    await _captureTelemetry();
    _animation.stop();
    await _loadDisplayRefreshRate();
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
      _status = result == null ? 'Benchmark iptal edildi.' : _rating(result.total);
    });
  }

  void _cancel() {
    BenchmarkService.cancel();
    setState(() => _status = 'Benchmark durduruluyor...');
  }

  String _rating(int score) {
    if (score >= 9000) return 'Ultra Performans';
    if (score >= 7500) return 'Amiral Gemisi';
    if (score >= 6000) return 'Çok Güçlü';
    if (score >= 4500) return 'Güçlü';
    if (score >= 3000) return 'İyi';
    if (score >= 1500) return 'Orta';
    return 'Temel';
  }

  Widget _score(IconData icon, String title, int? value) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value?.toString() ?? '--',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  List<double?> _series(double? Function(BenchmarkTelemetry value) select) =>
      _telemetry.map((point) => select(point.value)).toList(growable: false);

  String _range(double? Function(BenchmarkTelemetry value) select, String suffix,
      {int digits = 1}) {
    final values = _series(select).whereType<double>().toList();
    if (values.isEmpty) return 'Veri okunamadı';
    return '${values.first.toStringAsFixed(digits)} → ${values.last.toStringAsFixed(digits)} $suffix';
  }

  Widget _telemetryCard() {
    if (_telemetry.isEmpty) return const SizedBox.shrink();
    final cpu = _series((v) => v.cpuPercent);
    final gpu = _series((v) => v.gpuPercent);
    final battery = _series((v) => v.batteryPercent?.toDouble());
    final temp = _series((v) => v.temperatureC);
    final times = _telemetry
        .map((point) => point.elapsed.inMilliseconds / 1000.0)
        .toList(growable: false);
    final stress = _telemetry.map((point) {
      final values = [point.value.cpuPercent, point.value.gpuPercent]
          .whereType<double>()
          .toList();
      return values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    }).toList();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Benchmark Telemetrisi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Zaman serisi, benchmark boyunca cihazdan alınan gerçek örneklerdir.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _row('CPU', _range((v) => v.cpuPercent, '%')),
          _row('GPU', _range((v) => v.gpuPercent, '%')),
          _row('Batarya', _range((v) => v.batteryPercent?.toDouble(), '%', digits: 0)),
          _row('Sıcaklık', _range((v) => v.temperatureC, '°C')),
          _row('Stress Index', _range((v) {
            final values = [v.cpuPercent, v.gpuPercent].whereType<double>().toList();
            return values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
          }, '/100')),
          const SizedBox(height: 8),
          _Chart(title: 'CPU (%)', values: cpu, times: times, color: Colors.orange),
          _Chart(title: 'GPU (%)', values: gpu, times: times, color: Colors.purple),
          _Chart(title: 'Batarya (%)', values: battery, times: times, color: Colors.green),
          _Chart(title: 'Sıcaklık (°C)', values: temp, times: times, color: Colors.redAccent),
          _Chart(title: 'Stress Index (0–100)', values: stress, times: times, color: Colors.blue),
          const SizedBox(height: 6),
          Text(
            'Stress Index standart bir benchmark metriği değildir; okunabilen CPU/GPU kullanım yüzdelerinin ortalamasıdır. GPU sistem verisi erişilemezse grafik boş kalır; 0 olarak gösterilmez.',
            style: TextStyle(fontSize: 11, height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }

  Widget _graphicsCard(GraphicsBenchmarkResult? graphics) {
    if (graphics == null) {
      return const Card(
        margin: EdgeInsets.only(top: 12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('4K 120 FPS grafik testi çalıştırılamadı.'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('4K 120 FPS Video Decoder',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          _row('Çözünürlük', '${graphics.videoWidth} × ${graphics.videoHeight}'),
          _row('Kaynak FPS', '${graphics.videoFps.toStringAsFixed(1)} FPS'),
          _row('Ortalama FPS', '${graphics.averageFps.toStringAsFixed(1)} FPS'),
          _row('Minimum FPS', '${graphics.minimumFps.toStringAsFixed(1)} FPS'),
          _row('1% Low', '${graphics.onePercentLow.toStringAsFixed(1)} FPS'),
          _row('Dropped frames', graphics.droppedFrames.toString()),
          _row('Frame time', '${graphics.frameTimeMs.toStringAsFixed(2)} ms'),
          _row('Decoder processing', '${graphics.processingAverageMs.toStringAsFixed(2)} ms'),
          _Chart(
            title: 'Gerçek frame-release FPS örnekleri',
            values: graphics.fpsSamples.map((sample) => sample.fps).toList(),
            color: Theme.of(context).colorScheme.primary,
            times: graphics.fpsSamples.map((sample) => sample.timeSeconds).toList(growable: false),
          ),
          Text(
            graphics.fpsSamples.isEmpty
                ? 'Zaman serisi ölçülemedi; yalnızca özet değerler mevcut.'
                : 'X ekseni: test süresi. FPS örnekleri Media3 frame-release zamanlarından hesaplanır.',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
        centerTitle: true,
        actions: [
          if (_running)
            IconButton(onPressed: _cancel, icon: const Icon(Icons.stop_circle_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) => Transform.rotate(
                    angle: _running ? _animation.value * math.pi * 2 : 0,
                    child: Icon(Icons.speed_rounded, size: 46, color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(result?.total.toString() ?? '--',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: scheme.primary)),
                const Text('STELLAR SCORE',
                    style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(_status, textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          if (_running) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress, minHeight: 8),
            const SizedBox(height: 6),
            Text('${(_progress * 100).round()}%', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 14),
          _score(Icons.memory_rounded, 'CPU Single-Core', result?.singleCore),
          _score(Icons.developer_board_rounded, 'CPU Multi-Core', result?.multiCore),
          _score(Icons.sd_storage_rounded, 'RAM', result?.ram),
          _score(Icons.storage_rounded, 'Storage', result?.storage),
          _score(Icons.graphic_eq_rounded, 'Graphics / Video', result?.graphics),
          _score(Icons.speed_rounded, 'Mixed System', result?.mixed),
          if (result != null) _graphicsCard(result.graphicsResult),
          _telemetryCard(),
          const SizedBox(height: 14),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _running ? null : _start,
              icon: Icon(_running ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
              label: Text(_running ? 'Test çalışıyor...' : 'Benchmark Başlat'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stellar Benchmark gerçek CPU, RAM, depolama, video decoder ve karma yük ölçümleri kullanır. Okunamayan sistem verileri skor veya grafik olarak uydurulmaz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final String title;
  final List<double?> values;
  final List<double>? times;
  final Color color;

  const _Chart({required this.title, required this.values, this.times, required this.color});

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((value) => value != null);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        SizedBox(
          height: 100,
          width: double.infinity,
          child: hasData
              ? CustomPaint(painter: _LineChartPainter(values, color, times))
              : Center(
                  child: Text('Veri okunamadı',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
        ),
      ]),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double?> values;
  final Color color;
  final List<double>? times;

  _LineChartPainter(this.values, this.color, this.times);

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return;
    final minimum = present.reduce(math.min);
    final maximum = present.reduce(math.max);
    final span = math.max(1.0, maximum - minimum);
    final grid = Paint()..color = color.withOpacity(.16)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Path? path;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        path = null;
        continue;
      }
      final validTimes =
          times != null && times!.length == values.length ? times! : null;
      final xValues = validTimes ?? List<double>.generate(
        values.length,
        (index) => index.toDouble(),
      );
      final minX = xValues.reduce(math.min);
      final maxX = xValues.reduce(math.max);
      final xSpan = math.max(1.0, maxX - minX);
      final x = size.width * (xValues[i] - minX) / xSpan;
      final y = size.height - ((value - minimum) / span * size.height);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path!.lineTo(x, y);
      }
      canvas.drawPath(path!, line);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color || oldDelegate.times != times;
}
