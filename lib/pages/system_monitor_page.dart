import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key});

  @override
  State<SystemMonitorPage> createState() =>
      _SystemMonitorPageState();
}

class _SystemMonitorPageState
    extends State<SystemMonitorPage> {
  Timer? _timer;

  int _battery = 0;
  String _batteryState = 'Bilinmiyor';

  double _memoryUsed = 0;
  double _memoryTotal = 0;

  double _cpuUsage = 0;

  @override
  void initState() {
    super.initState();

    _update();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  Future<void> _update() async {
    await Future.wait([
      _updateBattery(),
      _updateMemory(),
      _updateCpu(),
    ]);
  }

  Future<void> _updateBattery() async {
    try {
      final battery = Battery();

      final level =
          await battery.batteryLevel;

      final state =
          await battery.batteryState;

      if (!mounted) return;

      setState(() {
        _battery = level;

        switch (state) {
          case BatteryState.charging:
            _batteryState = 'Şarj oluyor';
            break;

          case BatteryState.discharging:
            _batteryState = 'Şarj olmuyor';
            break;

          case BatteryState.full:
            _batteryState = 'Dolu';
            break;

          case BatteryState.connectedNotCharging:
            _batteryState =
                'Bağlı, şarj olmuyor';
            break;

          case BatteryState.unknown:
            _batteryState = 'Bilinmiyor';
            break;
        }
      });
    } catch (_) {}
  }

  Future<void> _updateMemory() async {
    try {
      final file =
          File('/proc/meminfo');

      if (!await file.exists()) {
        return;
      }

      final content =
          await file.readAsString();

      int total = 0;
      int available = 0;

      for (final line
          in content.split('\n')) {
        if (line.startsWith('MemTotal:')) {
          total = _parseKb(line);
        }

        if (line.startsWith('MemAvailable:')) {
          available = _parseKb(line);
        }
      }

      if (!mounted) return;

      setState(() {
        _memoryTotal =
            total / 1024;

        _memoryUsed =
            (total - available) / 1024;
      });
    } catch (_) {}
  }

  int _parseKb(String line) {
    final parts =
        line.split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return 0;
    }

    return int.tryParse(parts[1]) ?? 0;
  }

  Future<void> _updateCpu() async {
    try {
      final file =
          File('/proc/loadavg');

      if (!await file.exists()) {
        return;
      }

      final content =
          await file.readAsString();

      final parts =
          content.trim().split(' ');

      if (parts.isEmpty) {
        return;
      }

      final load =
          double.tryParse(parts[0]) ?? 0;

      final cores =
          Platform.numberOfProcessors;

      final usage =
          ((load / cores) * 100)
              .clamp(0, 100)
              .toDouble();

      if (!mounted) return;

      setState(() {
        _cpuUsage = usage;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _metric(
    String title,
    String value,
    IconData icon,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: scheme.primary,
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryPercentage =
        _memoryTotal <= 0
            ? 0
            : (_memoryUsed /
                    _memoryTotal *
                    100)
                .clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem İzleme',
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _metric(
            'CPU',
            '${_cpuUsage.toStringAsFixed(1)}%',
            Icons.memory,
          ),

          _metric(
            'RAM',
            '${_memoryUsed.toStringAsFixed(0)} / '
                '${_memoryTotal.toStringAsFixed(0)} MB',
            Icons.sd_memory,
          ),

          _metric(
            'RAM Kullanımı',
            '${memoryPercentage.toStringAsFixed(1)}%',
            Icons.bar_chart,
          ),

          _metric(
            'Pil',
            '$_battery%',
            Icons.battery_full,
          ),

          _metric(
            'Pil Durumu',
            _batteryState,
            Icons.bolt,
          ),

          const SizedBox(height: 12),

          Text(
            'Veriler yaklaşık 1 saniyede bir yenilenir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
