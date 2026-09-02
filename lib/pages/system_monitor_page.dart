import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemMonitorPage extends StatefulWidget {
  final dynamic selectedTheme;
  final dynamic selectedStyle;
  final ValueChanged<dynamic>? onThemeChanged;
  final ValueChanged<dynamic>? onStyleChanged;

  const SystemMonitorPage({
    super.key,
    this.selectedTheme,
    this.selectedStyle,
    this.onThemeChanged,
    this.onStyleChanged,
  });

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  Timer? _timer;

  double _cpuUsage = 0;
  int _ramTotal = 0;
  int _ramAvailable = 0;

  int _batteryLevel = -1;
  bool _isCharging = false;
  String _plugSource = 'None';
  double _batteryTemperature = -1;

  int _cpuCount = 0;
  int _onlineCpuCount = 0;
  String _onlineCpuList = 'Unknown';

  List<double> _cpuFrequencies = [];
  List<Map<String, dynamic>> _thermalZones = [];

  int? _previousTotal;
  int? _previousIdle;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _readCpu(),
      _readMemory(),
      _readBattery(),
      _readDetails(),
    ]);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _readCpu() async {
    try {
      final file = File('/proc/stat');

      if (!await file.exists()) {
        return;
      }

      final lines = await file.readAsLines();

      final cpuLine = lines.firstWhere(
        (line) => line.startsWith('cpu '),
        orElse: () => '',
      );

      if (cpuLine.isEmpty) {
        return;
      }

      final values = cpuLine
          .trim()
          .split(RegExp(r'\s+'))
          .skip(1)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      if (values.length < 5) {
        return;
      }

      final user = values[0];
      final nice = values[1];
      final system = values[2];
      final idle = values[3];
      final iowait = values[4];

      final total = values.fold<int>(0, (a, b) => a + b);
      final idleTotal = idle + iowait;

      if (_previousTotal != null && _previousIdle != null) {
        final totalDelta = total - _previousTotal!;
        final idleDelta = idleTotal - _previousIdle!;

        if (totalDelta > 0) {
          final usage =
              ((totalDelta - idleDelta) / totalDelta) * 100;

          _cpuUsage = usage.clamp(0, 100).toDouble();
        }
      }

      _previousTotal = total;
      _previousIdle = idleTotal;

      user;
      nice;
      system;
    } catch (_) {}
  }

  Future<void> _readMemory() async {
    try {
      final file = File('/proc/meminfo');

      if (!await file.exists()) {
        return;
      }

      final lines = await file.readAsLines();

      int parseValue(String key) {
        final line = lines.firstWhere(
          (line) => line.startsWith(key),
          orElse: () => '',
        );

        if (line.isEmpty) {
          return 0;
        }

        final match = RegExp(r'(\d+)').firstMatch(line);

        if (match == null) {
          return 0;
        }

        return int.tryParse(match.group(1)!) ?? 0;
      }

      _ramTotal = parseValue('MemTotal:');
      _ramAvailable = parseValue('MemAvailable:');
    } catch (_) {}
  }

  Future<void> _readBattery() async {
    try {
      final result =
          await _channel.invokeMethod<dynamic>(
        'getBatteryStatus',
      );

      if (result is! Map) {
        return;
      }

      _batteryLevel =
          (result['level'] as num?)?.toInt() ?? -1;

      _isCharging =
          result['isCharging'] == true;

      _plugSource =
          result['plugSource']?.toString() ?? 'None';

      _batteryTemperature =
          (result['temperature'] as num?)?.toDouble() ?? -1;
    } catch (_) {}
  }

  Future<void> _readDetails() async {
    try {
      final result =
          await _channel.invokeMethod<dynamic>(
        'getSystemMonitorDetails',
      );

      if (result is! Map) {
        return;
      }

      _cpuCount =
          (result['cpu_count'] as num?)?.toInt() ?? 0;

      _onlineCpuCount =
          (result['online_cpu_count'] as num?)?.toInt() ?? 0;

      _onlineCpuList =
          result['online_cpu_list']?.toString() ?? 'Unknown';

      final frequencies =
          result['cpu_frequencies'];

      if (frequencies is List) {
        _cpuFrequencies = frequencies
            .map(
              (value) =>
                  (value as num?)?.toDouble() ?? -1,
            )
            .toList();
      }

      final thermal =
          result['thermal_zones'];

      if (thermal is List) {
        _thermalZones = thermal
            .whereType<Map>()
            .map(
              (zone) => Map<String, dynamic>.from(zone),
            )
            .toList();
      }
    } catch (_) {}
  }

  String _formatRam(int kb) {
    if (kb <= 0) {
      return 'N/A';
    }

    final gb = kb / 1024 / 1024;

    if (gb >= 1) {
      return '${gb.toStringAsFixed(2)} GB';
    }

    return '${(kb / 1024).toStringAsFixed(0)} MB';
  }

  String _formatFrequency(double value) {
    if (value <= 0) {
      return 'N/A';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} GHz';
    }

    return '${value.toStringAsFixed(0)} MHz';
  }

  Color _usageColor(double value) {
    if (value >= 85) {
      return Colors.red;
    }

    if (value >= 65) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _progress(
    double value,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        minHeight: 10,
        value: value.clamp(0, 1),
        color: color,
        backgroundColor:
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ramUsed =
        _ramTotal > 0
            ? (_ramTotal - _ramAvailable).clamp(
                0,
                _ramTotal,
              )
            : 0;

    final ramUsage =
        _ramTotal > 0
            ? ramUsed / _ramTotal
            : 0.0;

    final batteryProgress =
        _batteryLevel >= 0
            ? _batteryLevel / 100
            : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem İzleme'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            _card(
              icon: Icons.speed,
              title: 'CPU',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kullanım'),
                      Text(
                        '${_cpuUsage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _progress(
                    _cpuUsage / 100,
                    _usageColor(_cpuUsage),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Çekirdek: $_onlineCpuCount / $_cpuCount aktif',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Online: $_onlineCpuList',
                  ),
                ],
              ),
            ),

            _card(
              icon: Icons.memory,
              title: 'RAM',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kullanım'),
                      Text(
                        '${(ramUsage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _progress(
                    ramUsage,
                    _usageColor(ramUsage * 100),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Kullanılan: ${_formatRam(ramUsed)}',
                  ),
                  Text(
                    'Boş: ${_formatRam(_ramAvailable)}',
                  ),
                  Text(
                    'Toplam: ${_formatRam(_ramTotal)}',
                  ),
                ],
              ),
            ),

            _card(
              icon: Icons.developer_board,
              title: 'CPU Çekirdekleri',
              child: _cpuFrequencies.isEmpty
                  ? const Text(
                      'Çekirdek frekansı bu cihaz tarafından erişilebilir değil.',
                    )
                  : Column(
                      children: List.generate(
                        _cpuFrequencies.length,
                        (index) {
                          final frequency =
                              _cpuFrequencies[index];

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'CPU $index',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatFrequency(
                                      frequency,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            _card(
              icon: Icons.battery_full,
              title: 'Batarya',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _batteryLevel >= 0
                            ? '$_batteryLevel%'
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isCharging
                            ? Icons.bolt
                            : Icons.battery_std,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _progress(
                    batteryProgress,
                    _batteryLevel <= 20
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isCharging
                        ? 'Şarj oluyor'
                        : 'Şarj olmuyor',
                  ),
                  Text(
                    'Kaynak: $_plugSource',
                  ),
                  if (_batteryTemperature >= 0)
                    Text(
                      'Batarya sıcaklığı: '
                      '${_batteryTemperature.toStringAsFixed(1)} °C',
                    ),
                ],
              ),
            ),

            _card(
              icon: Icons.thermostat,
              title: 'Termal Sensörler',
              child: _thermalZones.isEmpty
                  ? const Text(
                      'Termal sensör bilgisi bu cihazda erişilebilir değil.',
                    )
                  : Column(
                      children: _thermalZones.map(
                        (zone) {
                          final type =
                              zone['type']?.toString() ??
                                  'Thermal zone';

                          final temperature =
                              (zone['temperature']
                                      as num?)
                                  ?.toDouble();

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.thermostat,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    type,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  temperature != null
                                      ? '${temperature.toStringAsFixed(1)} °C'
                                      : 'N/A',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
