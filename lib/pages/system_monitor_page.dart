import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class SystemMonitorPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const SystemMonitorPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<SystemMonitorPage> createState() =>
      _SystemMonitorPageState();
}

class _SystemMonitorPageState
    extends State<SystemMonitorPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  Timer? _timer;

  double _cpuUsage = 0;
  int _totalCpuCount = 0;
  int _onlineCpuCount = 0;

  List<String> _onlineCpus = [];
  List<double> _cpuFrequencies = [];

  double _ramTotal = 0;
  double _ramAvailable = 0;
  double _ramUsed = 0;

  int _batteryLevel = -1;
  String _batteryState = 'Bilinmiyor';
  String _batterySource = 'Bilinmiyor';
  double? _batteryTemperature;

  Map<String, double> _thermalZones = {};
  Map<String, dynamic> _deviceInfo = {};

  int _previousTotal = 0;
  int _previousIdle = 0;

  bool _loading = true;

  bool get _isGlass =>
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle ==
      AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();

    _loadAll();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _loadAll(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadCpu(),
      _loadRam(),
      _loadNative(),
      _loadDeviceInfo(),
    ]);

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadCpu() async {
    try {
      final file = File('/proc/stat');

      if (!await file.exists()) return;

      final lines = await file.readAsLines();

      final cpuLine = lines.firstWhere(
        (line) => line.startsWith('cpu '),
        orElse: () => '',
      );

      if (cpuLine.isEmpty) return;

      final parts = cpuLine.trim().split(
        RegExp(r'\s+'),
      );

      if (parts.length < 5) return;

      final values = parts
          .sublist(1)
          .take(8)
          .map(
            (e) => int.tryParse(e) ?? 0,
          )
          .toList();

      if (values.length < 4) return;

      final user = values[0];
      final nice = values[1];
      final system = values[2];
      final idle = values[3];
      final iowait =
          values.length > 4 ? values[4] : 0;
      final irq =
          values.length > 5 ? values[5] : 0;
      final softirq =
          values.length > 6 ? values[6] : 0;
      final steal =
          values.length > 7 ? values[7] : 0;

      final idleTime = idle + iowait;

      final totalTime =
          user +
          nice +
          system +
          idle +
          iowait +
          irq +
          softirq +
          steal;

      if (_previousTotal != 0) {
        final totalDelta =
            totalTime - _previousTotal;
        final idleDelta =
            idleTime - _previousIdle;

        if (totalDelta > 0) {
          final usage =
              1 -
              (idleDelta / totalDelta);

          if (mounted) {
            setState(() {
              _cpuUsage =
                  (usage * 100)
                      .clamp(0.0, 100.0)
                      .toDouble();
            });
          }
        }
      }

      _previousTotal = totalTime;
      _previousIdle = idleTime;

      final cpuCount = lines
          .where(
            (line) => RegExp(
              r'^cpu\d+\s',
            ).hasMatch(line),
          )
          .length;

      if (mounted) {
        setState(() {
          _totalCpuCount = cpuCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRam() async {
    try {
      final file = File('/proc/meminfo');

      if (!await file.exists()) return;

      final lines = await file.readAsLines();

      int? totalKb;
      int? availableKb;

      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          totalKb = int.tryParse(
            line.replaceAll(
              RegExp(r'[^0-9]'),
              '',
            ),
          );
        }

        if (line.startsWith(
          'MemAvailable:',
        )) {
          availableKb = int.tryParse(
            line.replaceAll(
              RegExp(r'[^0-9]'),
              '',
            ),
          );
        }
      }

      if (totalKb == null ||
          availableKb == null) {
        return;
      }

      final total =
          totalKb / (1024 * 1024);

      final available =
          availableKb / (1024 * 1024);

      final double used =
          (total - available)
              .clamp(0.0, total)
              .toDouble();

      if (!mounted) return;

      setState(() {
        _ramTotal = total;
        _ramAvailable = available;
        _ramUsed = used;
      });
    } catch (_) {}
  }

  Future<void> _loadNative() async {
    try {
      final result =
          await _channel.invokeMethod<
              Map<dynamic, dynamic>>(
        'getSystemMonitorDetails',
      );

      if (result == null || !mounted) return;

      final data = result.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      );

      final online = <String>[];

      final onlineRaw =
          data['online_cpus'];

      if (onlineRaw is List) {
        online.addAll(
          onlineRaw.map(
            (e) => e.toString(),
          ),
        );
      } else if (onlineRaw != null) {
        online.addAll(
          onlineRaw
              .toString()
              .split(',')
              .map((e) => e.trim())
              .where(
                (e) => e.isNotEmpty,
              ),
        );
      }

      final frequencies = <double>[];

      final frequencyRaw =
          data['cpu_frequencies'];

      if (frequencyRaw is List) {
        for (final value in frequencyRaw) {
          final parsed =
              double.tryParse(
            value.toString(),
          );

          if (parsed != null) {
            frequencies.add(parsed);
          }
        }
      }

      final thermal = <String, double>{};

      final thermalRaw =
          data['thermal_zones'];

      if (thermalRaw is Map) {
        thermalRaw.forEach(
          (key, value) {
            final parsed =
                double.tryParse(
              value.toString(),
            );

            if (parsed != null) {
              thermal[key.toString()] =
                  parsed;
            }
          },
        );
      }

      final batteryLevelRaw =
          data['battery_level'];

      final batteryLevel =
          batteryLevelRaw is num
              ? batteryLevelRaw.toInt()
              : int.tryParse(
                    batteryLevelRaw
                            ?.toString() ??
                        '',
                  ) ??
                  _batteryLevel;

      final temperatureRaw =
          data['battery_temperature'];

      double? temperature;

      if (temperatureRaw is num) {
        temperature =
            temperatureRaw.toDouble();
      } else {
        temperature =
            double.tryParse(
          temperatureRaw?.toString() ??
              '',
        );
      }

      setState(() {
        _onlineCpus = online;

        _onlineCpuCount =
            online.isNotEmpty
                ? online.length
                : _totalCpuCount;

        _cpuFrequencies =
            frequencies;

        _thermalZones = thermal;

        _batteryLevel =
            batteryLevel;

        _batteryState =
            data['battery_state']
                    ?.toString() ??
                _batteryState;

        _batterySource =
            data['battery_source']
                    ?.toString() ??
                _batterySource;

        _batteryTemperature =
            temperature;
      });
    } catch (_) {
      try {
        final result =
            await _channel.invokeMethod<
                Map<dynamic, dynamic>>(
          'getBatteryStatus',
        );

        if (result == null ||
            !mounted) {
          return;
        }

        setState(() {
          final level = result['level'];

          if (level is num) {
            _batteryLevel =
                level.toInt();
          }

          _batteryState =
              result['state']
                      ?.toString() ??
                  _batteryState;

          _batterySource =
              result['source']
                      ?.toString() ??
                  _batterySource;

          final temperature =
              result['temperature'];

          if (temperature is num) {
            _batteryTemperature =
                temperature.toDouble();
          }
        });
      } catch (_) {}
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final result =
          await _channel.invokeMethod<
              Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );

      if (result == null || !mounted) {
        return;
      }

      setState(() {
        _deviceInfo = result.map(
          (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    _previousTotal = 0;
    _previousIdle = 0;

    await _loadAll();
  }

  String _value(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text == 'null') {
      return 'Bilinmiyor';
    }

    return text;
  }

  String _ramText(double value) {
    if (value <= 0) return '--';

    return '${value.toStringAsFixed(1)} GB';
  }

  String _frequencyText(
    double value,
  ) {
    if (value <= 0) return '--';

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} GHz';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} MHz';
    }

    return '${value.toStringAsFixed(0)} kHz';
  }

  String _temperatureText(
    double? value,
  ) {
    if (value == null) return '--';

    return '${value.toStringAsFixed(1)} °C';
  }

  Color _cpuColor(double value) {
    final scheme =
        Theme.of(context).colorScheme;

    if (value >= 90) {
      return scheme.error;
    }

    if (value >= 70) {
      return Colors.orange;
    }

    return scheme.primary;
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding =
        const EdgeInsets.all(18),
  }) {
    final scheme =
        Theme.of(context).colorScheme;

    if (!_isGlass) {
      return Card(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(25),
              color:
                  Colors.white.withOpacity(
                _isLightGlass
                    ? 0.15
                    : 0.065,
              ),
              border: Border.all(
                color:
                    Colors.white.withOpacity(
                  _isLightGlass
                      ? 0.55
                      : 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    _isLightGlass
                        ? 0.06
                        : 0.18,
                  ),
                  blurRadius: 28,
                  spreadRadius: -8,
                  offset:
                      const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: padding,
                  child: child,
                ),
                Positioned(
                  top: 0,
                  left: 18,
                  right: 18,
                  height: 1.4,
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white
                              .withOpacity(
                            _isLightGlass
                                ? 0.80
                                : 0.35,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    final scheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        4,
        12,
        4,
        9,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color:
              scheme.onSurfaceVariant,
        ),
      ),
    );
  }  Widget _summaryCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final model =
        _value(_deviceInfo['model']);

    final manufacturer =
        _value(
      _deviceInfo['manufacturer'],
    );

    final android =
        _value(
      _deviceInfo['release'],
    );

    final sdk =
        _value(
      _deviceInfo['sdk_int'],
    );

    final board =
        _value(
      _deviceInfo['board'],
    );

    final kernel =
        _value(
      _deviceInfo['kernel_version'],
    );

    final storage =
        _value(
      _deviceInfo['total_storage'],
    );

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: scheme.primary
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: scheme.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      manufacturer,
                      style: TextStyle(
                        color: scheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _infoRow(
            'Android',
            android,
            Icons.android_rounded,
          ),
          _infoRow(
            'SDK',
            sdk,
            Icons.code_rounded,
          ),
          _infoRow(
            'Board',
            board,
            Icons.developer_board_rounded,
          ),
          _infoRow(
            'Depolama',
            storage,
            Icons.storage_rounded,
          ),
          _infoRow(
            'Kernel',
            kernel,
            Icons.terminal_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    IconData icon,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cpuCard() {
    final color =
        _cpuColor(_cpuUsage);

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CPU kullanımı',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_cpuUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              minHeight: 9,
              value:
                  (_cpuUsage / 100)
                      .clamp(0.0, 1.0),
              backgroundColor:
                  color.withOpacity(0.10),
              valueColor:
                  AlwaysStoppedAnimation(
                color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_onlineCpuCount / $_totalCpuCount çekirdek aktif',
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

  Widget _ramCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final percent =
        _ramTotal <= 0
            ? 0.0
            : (_ramUsed / _ramTotal)
                .clamp(0.0, 1.0);

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'RAM',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_ramText(_ramUsed)} / ${_ramText(_ramTotal)}',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              minHeight: 9,
              value: percent,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${_ramText(_ramAvailable)} kullanılabilir',
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

  Widget _batteryCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final level =
        _batteryLevel < 0
            ? 0.0
            : (_batteryLevel / 100)
                .clamp(0.0, 1.0);

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_full_rounded,
                color: scheme.primary,
                size: 31,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pil',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _batteryState,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _batteryLevel < 0
                    ? '--'
                    : '$_batteryLevel%',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              minHeight: 8,
              value: level,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _batterySource,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _temperatureText(
                  _batteryTemperature,
                ),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cpuDetails() {
    final scheme =
        Theme.of(context).colorScheme;

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'İşlemci ayrıntıları',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          _infoRow(
            'Toplam çekirdek',
            '$_totalCpuCount',
            Icons.developer_board_rounded,
          ),
          _infoRow(
            'Aktif çekirdek',
            '$_onlineCpuCount',
            Icons.power_rounded,
          ),
          if (_cpuFrequencies
              .isNotEmpty)
            ..._cpuFrequencies
                .take(12)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => _infoRow(
                    'CPU ${entry.key}',
                    _frequencyText(
                      entry.value,
                    ),
                    Icons.speed_rounded,
                  ),
                )
          else
            Text(
              'Frekans bilgisi alınamadı.',
              style: TextStyle(
                color: scheme
                    .onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _thermalCard() {
    final scheme =
        Theme.of(context).colorScheme;

    if (_thermalZones.isEmpty) {
      return _card(
        child: Row(
          children: [
            Icon(
              Icons.thermostat_rounded,
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Termal sensör bilgisi alınamadı.',
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Termal sensörler',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ..._thermalZones.entries
              .take(20)
              .map(
                (entry) => _infoRow(
                  entry.key,
                  _temperatureText(
                    entry.value,
                  ),
                  Icons.thermostat_rounded,
                ),
              ),
        ],
      ),
    );
  }

  Widget _onlineCpuCard() {
    final scheme =
        Theme.of(context).colorScheme;

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktif CPU çekirdekleri',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _onlineCpus.isEmpty
                    ? [
                        Text(
                          'Bilgi alınamadı.',
                          style:
                              TextStyle(
                            color: scheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ]
                    : _onlineCpus
                        .map(
                          (cpu) =>
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  12,
                              vertical: 7,
                            ),
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              color: scheme
                                  .primary
                                  .withOpacity(
                                0.10,
                              ),
                            ),
                            child: Text(
                              'CPU $cpu',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      children: [
        IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -100,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary
                        .withOpacity(
                          _isGlass
                              ? 0.07
                              : 0.025,
                        ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -150,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary
                        .withOpacity(
                          _isGlass
                              ? 0.04
                              : 0.02,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              110,
            ),
            children: [
              const Padding(
                padding:
                    EdgeInsets.only(
                  left: 4,
                  bottom: 5,
                ),
                child: Text(
                  'Sistem Monitörü',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Cihazın gerçek zamanlı durumu',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              _title(
                'Sistem Özeti',
              ),
              _summaryCard(),
              _title(
                'Gerçek Zamanlı',
              ),
              _cpuCard(),
              _ramCard(),
              _batteryCard(),
              _title('İşlemci'),
              _cpuDetails(),
              _onlineCpuCard(),
              _title('Termal'),
              _thermalCard(),
              if (_loading)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 12,
                  ),
                  child:
                      LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
