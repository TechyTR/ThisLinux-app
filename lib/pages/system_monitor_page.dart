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
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  Timer? _timer;

  double _cpuUsage = 0;
  int _onlineCpuCount = 0;
  int _totalCpuCount = 0;

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

  int _previousTotal = 0;
  int _previousIdle = 0;

  bool _loading = true;

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();

    _loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCpuUsage(),
      _loadRam(),
      _loadNativeDetails(),
    ]);

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadCpuUsage() async {
    try {
      final file = File('/proc/stat');

      if (!await file.exists()) return;

      final lines = await file.readAsLines();

      final cpuLine = lines.firstWhere(
        (line) => line.startsWith('cpu '),
        orElse: () => '',
      );

      if (cpuLine.isEmpty) return;

      final parts = cpuLine
          .trim()
          .split(RegExp(r'\s+'));

      if (parts.length < 5) return;

      final values = parts
          .sublist(1)
          .take(8)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      if (values.length < 4) return;

      final user = values[0];
      final nice = values[1];
      final system = values[2];
      final idle = values[3];

      final iowait = values.length > 4 ? values[4] : 0;
      final irq = values.length > 5 ? values[5] : 0;
      final softirq = values.length > 6 ? values[6] : 0;
      final steal = values.length > 7 ? values[7] : 0;

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
              1 - (idleDelta / totalDelta);

          if (mounted) {
            setState(() {
              _cpuUsage =
                  (usage * 100).clamp(0, 100);
            });
          }
        }
      }

      _previousTotal = totalTime;
      _previousIdle = idleTime;

      final cpuCount = lines
          .where(
            (line) =>
                RegExp(r'^cpu\d+\s').hasMatch(line),
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
            line.replaceAll(RegExp(r'[^0-9]'), ''),
          );
        }

        if (line.startsWith('MemAvailable:')) {
          availableKb = int.tryParse(
            line.replaceAll(RegExp(r'[^0-9]'), ''),
          );
        }
      }

      if (totalKb == null || availableKb == null) {
        return;
      }

      final total =
          totalKb / (1024 * 1024);

      final available =
          availableKb / (1024 * 1024);

      final used =
          (total - available).clamp(0, total);

      if (!mounted) return;

      setState(() {
        _ramTotal = total;
        _ramAvailable = available;
        _ramUsed = used;
      });
    } catch (_) {}
  }

  Future<void> _loadNativeDetails() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSystemMonitorDetails',
      );

      if (result == null || !mounted) return;

      final data = result.map(
        (key, value) => MapEntry(
          key.toString(),
          value,
        ),
      );

      final frequenciesRaw =
          data['cpu_frequencies'];

      final frequencies = <double>[];

      if (frequenciesRaw is List) {
        for (final value in frequenciesRaw) {
          final number = double.tryParse(
            value.toString(),
          );

          if (number != null) {
            frequencies.add(number);
          }
        }
      }

      final onlineRaw =
          data['online_cpus'];

      final online = <String>[];

      if (onlineRaw is List) {
        for (final value in onlineRaw) {
          online.add(value.toString());
        }
      } else if (onlineRaw != null) {
        online.addAll(
          onlineRaw
              .toString()
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
      }

      final thermalRaw =
          data['thermal_zones'];

      final thermal = <String, double>{};

      if (thermalRaw is Map) {
        thermalRaw.forEach(
          (key, value) {
            final number = double.tryParse(
              value.toString(),
            );

            if (number != null) {
              thermal[key.toString()] = number;
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
                    batteryLevelRaw?.toString() ?? '',
                  ) ??
                  _batteryLevel;

      final batteryTempRaw =
          data['battery_temperature'];

      final batteryTemperature =
          batteryTempRaw is num
              ? batteryTempRaw.toDouble()
              : double.tryParse(
                  batteryTempRaw?.toString() ?? '',
                );

      setState(() {
        _onlineCpus = online;

        _onlineCpuCount =
            online.isNotEmpty
                ? online.length
                : _totalCpuCount;

        _cpuFrequencies = frequencies;

        _batteryLevel = batteryLevel;

        _batteryState =
            data['battery_state']?.toString() ??
            _batteryState;

        _batterySource =
            data['battery_source']?.toString() ??
            _batterySource;

        _batteryTemperature =
            batteryTemperature;

        _thermalZones = thermal;
      });
    } catch (_) {
      try {
        final result =
            await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getBatteryStatus',
        );

        if (result == null || !mounted) return;

        setState(() {
          _batteryLevel =
              result['level'] is num
                  ? (result['level'] as num).toInt()
                  : _batteryLevel;

          _batteryState =
              result['state']?.toString() ??
              _batteryState;

          _batterySource =
              result['source']?.toString() ??
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

  Future<void> _refresh() async {
    _previousTotal = 0;
    _previousIdle = 0;

    await _loadData();
  }

  String _formatRam(double value) {
    if (value <= 0) return '--';

    return '${value.toStringAsFixed(1)} GB';
  }

  String _formatFrequency(double value) {
    if (value <= 0) return '--';

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} GHz';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} MHz';
    }

    return '${value.toStringAsFixed(0)} kHz';
  }

  String _formatTemperature(double? value) {
    if (value == null) return '--';

    return '${value.toStringAsFixed(1)} °C';
  }

  Color _usageColor(
    BuildContext context,
    double value,
  ) {
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

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
    double radius = 24,
  }) {
    if (!_isGlass) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(radius),
              color: Colors.white.withOpacity(
                _isLightGlass ? 0.15 : 0.065,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.58 : 0.20,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _isLightGlass ? 0.06 : 0.18,
                  ),
                  blurRadius: 26,
                  spreadRadius: -8,
                  offset: const Offset(0, 9),
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
                  left: 15,
                  right: 15,
                  top: 0,
                  height: 1.4,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(
                              _isLightGlass
                                  ? 0.78
                                  : 0.36,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          radius,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(
                              _isLightGlass
                                  ? 0.075
                                  : 0.03,
                            ),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                        ),
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

  Widget _sectionTitle(String title) {
    final scheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 12,
        bottom: 9,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _usageCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final usageColor =
        _usageColor(context, _cpuUsage);

    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: usageColor.withOpacity(
                    _isGlass ? 0.10 : 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: usageColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CPU kullanımı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gerçek zamanlı işlemci kullanımı',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_cpuUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: usageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _cpuUsage / 100,
              minHeight: 10,
              backgroundColor:
                  scheme.onSurface.withOpacity(
                _isGlass ? 0.06 : 0.10,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                size: 17,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                '$_onlineCpuCount / $_totalCpuCount çekirdek aktif',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ramCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final percentage =
        _ramTotal <= 0
            ? 0.0
            : (_ramUsed / _ramTotal)
                .clamp(0.0, 1.0);

    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: scheme.primary
                      .withOpacity(
                    _isGlass ? 0.09 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.memory_outlined,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'RAM',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(_ramUsed / (_ramTotal <= 0 ? 1 : _ramTotal) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatRam(_ramUsed)} kullanılıyor',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${_formatRam(_ramAvailable)} boş',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatRam(_ramTotal)} toplam',
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

  Widget _batteryCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final level =
        _batteryLevel.clamp(0, 100);

    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: scheme.primary
                      .withOpacity(
                    _isGlass ? 0.09 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _batteryState
                          .toLowerCase()
                          .contains('charg')
                      ? Icons
                          .battery_charging_full_rounded
                      : Icons.battery_full_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pil',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _batteryState,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _batteryLevel < 0
                    ? '--'
                    : '$level%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  _batteryLevel < 0
                      ? 0
                      : level / 100,
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kaynak: $_batterySource',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_batteryTemperature != null)
                Text(
                  _formatTemperature(
                    _batteryTemperature,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cpuDetailsCard() {
    final scheme =
        Theme.of(context).colorScheme;

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Çekirdekler',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_cpuFrequencies.isEmpty)
            Text(
              'Frekans bilgisi alınamadı.',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            )
          else
            ...List.generate(
              _cpuFrequencies.length,
              (index) {
                final active =
                    index < _onlineCpuCount;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 9,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment:
                            Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                                  .withOpacity(
                                  _isGlass
                                      ? 0.10
                                      : 0.12,
                                )
                              : scheme
                                  .onSurface
                                  .withOpacity(
                                  0.05,
                                ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                            color: active
                                ? scheme.primary
                                : scheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          active
                              ? 'CPU $index • Aktif'
                              : 'CPU $index • Çevrimdışı',
                          style: TextStyle(
                            fontSize: 12,
                            color: active
                                ? scheme.onSurface
                                : scheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        _formatFrequency(
                          _cpuFrequencies[index],
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _thermalCard() {
    final scheme =
        Theme.of(context).colorScheme;

    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.thermostat_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Sıcaklıklar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_thermalZones.isEmpty)
            Text(
              'Termal bölge bilgisi alınamadı.',
              style: TextStyle(
                fontSize: 12,
                color:
                    scheme.onSurfaceVariant,
              ),
            )
          else
            ..._thermalZones.entries.map(
              (entry) {
                final temperature =
                    entry.value;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: scheme.primary
                              .withOpacity(
                            _isGlass
                                ? 0.08
                                : 0.11,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          Icons
                              .device_thermostat_rounded,
                          size: 18,
                          color:
                              scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${temperature.toStringAsFixed(1)} °C',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              temperature >= 60
                                  ? scheme.error
                                  : scheme
                                      .onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _backgroundGlow(
    Alignment alignment,
    double size,
    double opacity,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 65,
          sigmaY: 65,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary
                .withOpacity(opacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem Monitörü',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isGlass) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  const Alignment(-1.15, -0.85),
                  250,
                  _isLightGlass
                      ? 0.10
                      : 0.075,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  const Alignment(1.15, 0.0),
                  260,
                  _isLightGlass
                      ? 0.075
                      : 0.055,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  const Alignment(0.25, 1.15),
                  230,
                  _isLightGlass
                      ? 0.06
                      : 0.045,
                ),
              ),
            ),
          ],

          RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              children: [
                _usageCard(),

                _sectionTitle(
                  'Bellek',
                ),

                _ramCard(),

                _sectionTitle(
                  'Pil',
                ),

                _batteryCard(),

                _sectionTitle(
                  'İşlemci detayları',
                ),

                _cpuDetailsCard(),

                _sectionTitle(
                  'Termal bölgeler',
                ),

                _thermalCard(),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Gerçek zamanlı sistem verileri',
                    style: TextStyle(
                      fontSize: 11,
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

          if (_loading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}

