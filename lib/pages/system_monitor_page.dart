import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({
    super.key,
  });

  @override
  State<SystemMonitorPage> createState() =>
      _SystemMonitorPageState();
}

class _SystemMonitorPageState
    extends State<SystemMonitorPage> {
  static const MethodChannel _channel =
      MethodChannel(
    'org.test.thislinux/native',
  );

  Timer? _timer;

  int _battery = -1;
  String _batteryState = 'Bilinmiyor';
  String _plugSource = 'None';
  double _batteryTemperature = -1;

  double _memoryUsed = 0;
  double _memoryTotal = 0;
  double _memoryAvailable = 0;

  double _cpuUsage = 0;

  int _cpuTotalPrevious = 0;
  int _cpuIdlePrevious = 0;
  bool _hasPreviousCpu = false;

  bool _loading = true;

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

    if (mounted && _loading) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateBattery() async {
    try {
      final result =
          await _channel.invokeMethod<
              Map<dynamic, dynamic>>(
        'getBatteryStatus',
      );

      if (result == null || !mounted) {
        return;
      }

      final level =
          _toInt(result['level']);

      final charging =
          result['isCharging'] == true;

      final plugSource =
          result['plugSource']
              ?.toString() ??
          'None';

      final temperature =
          _toDouble(
        result['temperature'],
      );

      String state;

      if (charging) {
        state = 'Şarj oluyor';
      } else if (level >= 100) {
        state = 'Dolu';
      } else {
        state = 'Şarj olmuyor';
      }

      setState(() {
        _battery = level;
        _batteryState = state;
        _plugSource = plugSource;
        _batteryTemperature =
            temperature;
      });
    } catch (_) {
      // Native battery bilgisi alınamazsa
      // mevcut değerler korunur.
    }
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

      int totalKb = 0;
      int availableKb = 0;

      for (final line
          in content.split('\n')) {
        if (line.startsWith(
          'MemTotal:',
        )) {
          totalKb = _parseKb(line);
        }

        if (line.startsWith(
          'MemAvailable:',
        )) {
          availableKb =
              _parseKb(line);
        }
      }

      if (!mounted) {
        return;
      }

      final usedKb =
          totalKb - availableKb;

      setState(() {
        _memoryTotal =
            totalKb / 1024;

        _memoryAvailable =
            availableKb / 1024;

        _memoryUsed =
            usedKb > 0
                ? usedKb / 1024
                : 0;
      });
    } catch (_) {}
  }

  int _parseKb(
    String line,
  ) {
    final parts =
        line.trim().split(
      RegExp(r'\s+'),
    );

    if (parts.length < 2) {
      return 0;
    }

    return int.tryParse(
          parts[1],
        ) ??
        0;
  }

  Future<void> _updateCpu() async {
    try {
      final file =
          File('/proc/stat');

      if (!await file.exists()) {
        return;
      }

      final content =
          await file.readAsString();

      String? cpuLine;

      for (final line
          in content.split('\n')) {
        if (line.startsWith('cpu ')) {
          cpuLine = line;
          break;
        }
      }

      if (cpuLine == null) {
        return;
      }

      final parts =
          cpuLine
              .trim()
              .split(
                RegExp(r'\s+'),
              );

      if (parts.length < 5) {
        return;
      }

      final values =
          parts
              .skip(1)
              .map(
                (value) =>
                    int.tryParse(value) ?? 0,
              )
              .toList();

      if (values.length < 4) {
        return;
      }

      final user = values[0];
      final nice = values[1];
      final system = values[2];
      final idle = values[3];

      final iowait =
          values.length > 4
              ? values[4]
              : 0;

      final irq =
          values.length > 5
              ? values[5]
              : 0;

      final softirq =
          values.length > 6
              ? values[6]
              : 0;

      final steal =
          values.length > 7
              ? values[7]
              : 0;

      final total =
          user +
          nice +
          system +
          idle +
          iowait +
          irq +
          softirq +
          steal;

      final effectiveIdle =
          idle + iowait;

      if (!_hasPreviousCpu) {
        _cpuTotalPrevious =
            total;

        _cpuIdlePrevious =
            effectiveIdle;

        _hasPreviousCpu = true;

        return;
      }

      final totalDelta =
          total -
          _cpuTotalPrevious;

      final idleDelta =
          effectiveIdle -
          _cpuIdlePrevious;

      _cpuTotalPrevious =
          total;

      _cpuIdlePrevious =
          effectiveIdle;

      if (totalDelta <= 0) {
        return;
      }

      final usage =
          ((totalDelta -
                  idleDelta) /
              totalDelta *
              100)
              .clamp(0, 100)
              .toDouble();

      if (!mounted) {
        return;
      }

      setState(() {
        _cpuUsage = usage;
      });
    } catch (_) {}
  }

  int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        -1;
  }

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        -1;
  }

  String _formatTemperature() {
    if (_batteryTemperature < 0) {
      return 'Bilinmiyor';
    }

    return '${_batteryTemperature.toStringAsFixed(1)} °C';
  }

  String _formatMemory(
    double value,
  ) {
    if (value <= 0) {
      return '--';
    }

    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(2)} GB';
    }

    return '${value.toStringAsFixed(0)} MB';
  }

  double _memoryPercentage() {
    if (_memoryTotal <= 0) {
      return 0;
    }

    return (_memoryUsed /
            _memoryTotal *
            100)
        .clamp(0, 100)
        .toDouble();
  }

  Widget _progressCard({
    required String title,
    required String value,
    required double progress,
    required IconData icon,
  }) {
    final scheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
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
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: scheme.primary
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        scheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  value,
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
              child:
                  LinearProgressIndicator(
                minHeight: 9,
                value: progress
                    .clamp(0, 1)
                    .toDouble(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final scheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 4,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color: scheme.primary
                .withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        trailing: Text(
          value,
          textAlign:
              TextAlign.end,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _batteryCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final batteryProgress =
        _battery < 0
            ? 0
            : (_battery / 100)
                .clamp(0, 1)
                .toDouble();

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: scheme.primary
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.battery_full,
                    color:
                        scheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Expanded(
                  child: Text(
                    'Pil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _battery < 0
                      ? '--'
                      : '$_battery%',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
              child:
                  LinearProgressIndicator(
                minHeight: 9,
                value:
                    batteryProgress,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Expanded(
                  child: _smallBatteryInfo(
                    'Durum',
                    _batteryState,
                  ),
                ),
                Expanded(
                  child: _smallBatteryInfo(
                    'Kaynak',
                    _plugSource,
                  ),
                ),
                Expanded(
                  child: _smallBatteryInfo(
                    'Sıcaklık',
                    _formatTemperature(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBatteryInfo(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          textAlign:
              TextAlign.center,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final memoryPercentage =
        _memoryPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem İzleme',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _update,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _update,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(20),
                children: [
                  _progressCard(
                    title: 'CPU',
                    value:
                        '${_cpuUsage.toStringAsFixed(1)}%',
                    progress:
                        _cpuUsage / 100,
                    icon: Icons.memory,
                  ),

                  _progressCard(
                    title: 'RAM',
                    value:
                        '${memoryPercentage.toStringAsFixed(1)}%',
                    progress:
                        memoryPercentage /
                            100,
                    icon:
                        Icons.sd_memory,
                  ),

                  _metricCard(
                    title:
                        'Kullanılan RAM',
                    value:
                        _formatMemory(
                      _memoryUsed,
                    ),
                    icon:
                        Icons.memory,
                  ),

                  _metricCard(
                    title:
                        'Toplam RAM',
                    value:
                        _formatMemory(
                      _memoryTotal,
                    ),
                    icon:
                        Icons.memory_outlined,
                  ),

                  _metricCard(
                    title:
                        'Boş RAM',
                    value:
                        _formatMemory(
                      _memoryAvailable,
                    ),
                    icon:
                        Icons.space_bar,
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  _batteryCard(),

                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 18,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'CPU ve RAM verileri '
                            'yaklaşık her saniye yenilenir.',
                            style:
                                TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
    );
  }
}
