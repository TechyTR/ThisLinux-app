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

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _readCpu() async {
    try {
      final file = File('/proc/stat');

      if (!await file.exists()) return;

      final lines = await file.readAsLines();

      final cpuLine = lines.firstWhere(
        (line) => line.startsWith('cpu '),
        orElse: () => '',
      );

      if (cpuLine.isEmpty) return;

      final values = cpuLine
          .trim()
          .split(RegExp(r'\s+'))
          .skip(1)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      if (values.length < 5) return;

      final idle = values[3];
      final iowait = values[4];

      final total = values.fold<int>(
        0,
        (sum, value) => sum + value,
      );

      final idleTotal = idle + iowait;

      if (_previousTotal != null &&
          _previousIdle != null) {
        final totalDelta =
            total - _previousTotal!;

        final idleDelta =
            idleTotal - _previousIdle!;

        if (totalDelta > 0) {
          final usage =
              ((totalDelta - idleDelta) /
                      totalDelta) *
                  100;

          _cpuUsage =
              usage.clamp(0, 100).toDouble();
        }
      }

      _previousTotal = total;
      _previousIdle = idleTotal;
    } catch (_) {}
  }

  Future<void> _readMemory() async {
    try {
      final file = File('/proc/meminfo');

      if (!await file.exists()) return;

      final lines = await file.readAsLines();

      int readValue(String key) {
        final line = lines.firstWhere(
          (line) => line.startsWith(key),
          orElse: () => '',
        );

        if (line.isEmpty) return 0;

        final match =
            RegExp(r'(\d+)').firstMatch(line);

        if (match == null) return 0;

        return int.tryParse(
              match.group(1)!,
            ) ??
            0;
      }

      _ramTotal = readValue('MemTotal:');
      _ramAvailable =
          readValue('MemAvailable:');
    } catch (_) {}
  }

  Future<void> _readBattery() async {
    try {
      final result =
          await _channel.invokeMethod<dynamic>(
        'getBatteryStatus',
      );

      if (result is! Map) return;

      _batteryLevel =
          (result['level'] as num?)
                  ?.toInt() ??
              -1;

      _isCharging =
          result['isCharging'] == true;

      _plugSource =
          result['plugSource']?.toString() ??
              'None';

      _batteryTemperature =
          (result['temperature'] as num?)
                  ?.toDouble() ??
              -1;
    } catch (_) {}
  }

  Future<void> _readDetails() async {
    try {
      final result =
          await _channel.invokeMethod<dynamic>(
        'getSystemMonitorDetails',
      );

      if (result is! Map) return;

      _cpuCount =
          (result['cpu_count'] as num?)
                  ?.toInt() ??
              0;

      _onlineCpuCount =
          (result['online_cpu_count'] as num?)
                  ?.toInt() ??
              0;

      _onlineCpuList =
          result['online_cpu_list']?.toString() ??
              'Unknown';

      final frequencies =
          result['cpu_frequencies'];

      if (frequencies is List) {
        _cpuFrequencies = frequencies
            .map(
              (value) =>
                  (value as num?)
                      ?.toDouble() ??
                  -1,
            )
            .toList();
      }

      final thermal =
          result['thermal_zones'];

      if (thermal is List) {
        _thermalZones = thermal
            .whereType<Map>()
            .map(
              (zone) =>
                  Map<String, dynamic>.from(zone),
            )
            .toList();
      }
    } catch (_) {}
  }

  String _formatRam(int kb) {
    if (kb <= 0) return 'N/A';

    final gb =
        kb / 1024 / 1024;

    if (gb >= 1) {
      return '${gb.toStringAsFixed(2)} GB';
    }

    return '${(kb / 1024).toStringAsFixed(0)} MB';
  }

  String _formatFrequency(double value) {
    if (value <= 0) return 'N/A';

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} GHz';
    }

    return '${value.toStringAsFixed(0)} MHz';
  }

  Color _statusColor(double percentage) {
    if (percentage >= 85) {
      return Colors.red;
    }

    if (percentage >= 65) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Color _temperatureColor(double temperature) {
    if (temperature >= 70) {
      return Colors.red;
    }

    if (temperature >= 55) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
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

  Widget _progressBar({
    required double value,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(8),
      child: LinearProgressIndicator(
        minHeight: 9,
        value: value.clamp(0, 1),
        color: color,
        backgroundColor:
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
      ),
    );
  }

  Widget _metricRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ramUsed =
        _ramTotal > 0
            ? (_ramTotal - _ramAvailable)
                .clamp(0, _ramTotal)
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
        title: const Text(
          'Sistem İzleme',
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [

            _sectionCard(
              icon: Icons.speed,
              title: 'CPU',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anlık kullanım',
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${_cpuUsage.toStringAsFixed(1)}%',
                              style:
                                  const TextStyle(
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.memory,
                        size: 38,
                        color: _statusColor(
                          _cpuUsage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _progressBar(
                    value: _cpuUsage / 100,
                    color: _statusColor(
                      _cpuUsage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _metricRow(
                    'Toplam çekirdek',
                    '$_cpuCount',
                  ),
                  _metricRow(
                    'Aktif çekirdek',
                    '$_onlineCpuCount',
                  ),
                  _metricRow(
                    'Online CPU',
                    _onlineCpuList,
                  ),
                ],
              ),
            ),

            _sectionCard(
              icon: Icons.memory,
              title: 'RAM',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kullanım',
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${(ramUsage * 100).toStringAsFixed(1)}%',
                              style:
                                  const TextStyle(
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.memory,
                        size: 38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _progressBar(
                    value: ramUsage,
                    color: _statusColor(
                      ramUsage * 100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _metricRow(
                    'Kullanılan',
                    _formatRam(ramUsed),
                  ),
                  _metricRow(
                    'Boş',
                    _formatRam(
                      _ramAvailable,
                    ),
                  ),
                  _metricRow(
                    'Toplam',
                    _formatRam(
                      _ramTotal,
                    ),
                  ),
                ],
              ),
            ),

            _sectionCard(
              icon: Icons.developer_board,
              title: 'CPU Çekirdekleri',
              child: _cpuFrequencies.isEmpty
                  ? const Text(
                      'Çekirdek frekansı '
                      'bu cihaz tarafından '
                      'erişilebilir değil.',
                    )
                  : Column(
                      children: List.generate(
                        _cpuFrequencies.length,
                        (index) {
                          final frequency =
                              _cpuFrequencies[index];

                          final active =
                              index <
                                  _onlineCpuCount;

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 8,
                            ),
                            padding:
                                const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    color: active
                                        ? Theme.of(
                                            context,
                                          )
                                            .colorScheme
                                            .primary
                                        : Theme.of(
                                            context,
                                          )
                                            .colorScheme
                                            .outline,
                                  ),
                                  child: Icon(
                                    active
                                        ? Icons.bolt
                                        : Icons.power_off,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'CPU $index',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        active
                                            ? 'Aktif'
                                            : 'Pasif',
                                        style:
                                            Theme.of(
                                          context,
                                        )
                                                .textTheme
                                                .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatFrequency(
                                    frequency,
                                  ),
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
                      ),
                    ),
            ),

            _sectionCard(
              icon: Icons.battery_full,
              title: 'Batarya',
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _batteryLevel >= 0
                              ? '$_batteryLevel%'
                              : 'N/A',
                          style:
                              const TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isCharging
                            ? Icons.bolt
                            : Icons.battery_std,
                        size: 38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _progressBar(
                    value: batteryProgress,
                    color:
                        _batteryLevel >= 0 &&
                                _batteryLevel <= 20
                            ? Colors.red
                            : Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _metricRow(
                    'Durum',
                    _isCharging
                        ? 'Şarj oluyor'
                        : 'Şarj olmuyor',
                  ),
                  _metricRow(
                    'Kaynak',
                    _plugSource,
                  ),
                  if (_batteryTemperature >= 0)
                    _metricRow(
                      'Sıcaklık',
                      '${_batteryTemperature.toStringAsFixed(1)} °C',
                    ),
                ],
              ),
            ),

            _sectionCard(
              icon: Icons.thermostat,
              title: 'Termal Sensörler',
              child: _thermalZones.isEmpty
                  ? const Text(
                      'Termal sensör bilgisi '
                      'bu cihazda erişilebilir değil.',
                    )
                  : Column(
                      children:
                          _thermalZones.map(
                        (zone) {
                          final type =
                              zone['type']
                                  ?.toString() ??
                                  'Thermal zone';

                          final temperature =
                              (zone['temperature']
                                      as num?)
                                  ?.toDouble();

                          final temp =
                              temperature ?? -1;

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 8,
                            ),
                            padding:
                                const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thermostat,
                                  color:
                                      temp >= 0
                                          ? _temperatureColor(
                                              temp,
                                            )
                                          : null,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Text(
                                    type,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),
                                ),
                                Text(
                                  temp >= 0
                                      ? '${temp.toStringAsFixed(1)} °C'
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
                padding:
                    EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

