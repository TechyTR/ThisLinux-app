
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

      final parts = cpuLine.trim().split(RegExp(r'\s+'));

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
        final totalDelta = totalTime - _previousTotal;
        final idleDelta = idleTime - _previousIdle;

        if (totalDelta > 0) {
          final usage = 1 - (idleDelta / totalDelta);

          if (mounted) {
            setState(() {
              _cpuUsage =
                  (usage * 100).clamp(0.0, 100.0).toDouble();
            });
          }
        }
      }

      _previousTotal = totalTime;
      _previousIdle = idleTime;

      final cpuCount = lines
          .where(
            (line) => RegExp(r'^cpu\d+\s').hasMatch(line),
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

      final total = totalKb / (1024 * 1024);
      final available = availableKb / (1024 * 1024);

      // FIX:
      // clamp() returns num, so explicitly convert it to double.
      final double used =
          (total - available).clamp(0.0, total).toDouble();

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

      final frequenciesRaw = data['cpu_frequencies'];

      final frequencies = <double>[];

      if (frequenciesRaw is List) {
        for (final value in frequenciesRaw) {
          final number = double.tryParse(value.toString());

          if (number != null) {
            frequencies.add(number);
          }
        }
      }

      final onlineRaw = data['online_cpus'];

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

      final thermalRaw = data['thermal_zones'];

      final thermal = <String, double>{};

      if (thermalRaw is Map) {
        thermalRaw.forEach(
          (key, value) {
            final number = double.tryParse(value.toString());

            if (number != null) {
              thermal[key.toString()] = number;
            }
          },
        );
      }

      final batteryLevelRaw = data['battery_level'];

      final batteryLevel = batteryLevelRaw is num
          ? batteryLevelRaw.toInt()
          : int.tryParse(
                batteryLevelRaw?.toString() ?? '',
              ) ??
              _batteryLevel;

      final batteryTempRaw = data['battery_temperature'];

      final batteryTemperature = batteryTempRaw is num
          ? batteryTempRaw.toDouble()
          : double.tryParse(
              batteryTempRaw?.toString() ?? '',
            );

      setState(() {
        _onlineCpus = online;

        _onlineCpuCount =
            online.isNotEmpty ? online.length : _totalCpuCount;

        _cpuFrequencies = frequencies;

        _batteryLevel = batteryLevel;

        _batteryState =
            data['battery_state']?.toString() ?? _batteryState;

        _batterySource =
            data['battery_source']?.toString() ?? _batterySource;

        _batteryTemperature = batteryTemperature;

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
          _batteryLevel = result['level'] is num
              ? (result['level'] as num).toInt()
              : _batteryLevel;

          _batteryState =
              result['state']?.toString() ?? _batteryState;

          _batterySource =
              result['source']?.toString() ?? _batterySource;

          final temperature = result['temperature'];

          if (temperature is num) {
            _batteryTemperature = temperature.toDouble();
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
    final scheme = Theme.of(context).colorScheme;

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
        borderRadius: BorderRadius.circular(radius),
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
                            BorderRadius.circular(radius),
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
    final scheme = Theme.of(context).colorScheme;

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
    final scheme = Theme.of(context).colorScheme;

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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value:
                  (_cpuUsage / 100).clamp(0.0, 1.0),
              backgroundColor:
                  scheme.onSurface.withOpacity(
                _isGlass ? 0.08 : 0.10,
              ),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                usageColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.memory_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _totalCpuCount > 0
                    ? '$_totalCpuCount CPU çekirdeği'
                    : 'CPU çekirdekleri algılanıyor',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                _onlineCpuCount > 0
                    ? '$_onlineCpuCount aktif'
                    : 'Aktif çekirdek --',
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
    final scheme = Theme.of(context).colorScheme;

    final percent = _ramTotal > 0
        ? (_ramUsed / _ramTotal)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

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
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.10 : 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bellek kullanımı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _ramTotal > 0
                          ? '${_formatRam(_ramUsed)} / ${_formatRam(_ramTotal)}'
                          : 'RAM bilgisi okunuyor',
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
                _ramTotal > 0
                    ? '${(percent * 100).toStringAsFixed(1)}%'
                    : '--',
                style: TextStyle(
                  fontSize: 20,
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
              minHeight: 8,
              value: percent,
              backgroundColor:
                  scheme.onSurface.withOpacity(
                _isGlass ? 0.08 : 0.10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Kullanılan: ${_formatRam(_ramUsed)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Boş: ${_formatRam(_ramAvailable)}',
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

  Widget _batteryCard() {
    final scheme = Theme.of(context).colorScheme;

    final level =
        _batteryLevel.clamp(0, 100);

    final batteryColor =
        level <= 15
            ? scheme.error
            : level <= 30
                ? Colors.orange
                : scheme.primary;

    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      batteryColor.withOpacity(
                    _isGlass ? 0.10 : 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  level >= 90
                      ? Icons.battery_full_rounded
                      : level >= 60
                          ? Icons.battery_6_bar_rounded
                          : level >= 30
                              ? Icons.battery_4_bar_rounded
                              : Icons.battery_2_bar_rounded,
                  color: batteryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Batarya',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _batteryLevel >= 0
                          ? '$_batteryState • $_batterySource'
                          : 'Batarya bilgisi okunuyor',
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
                _batteryLevel >= 0
                    ? '$_batteryLevel%'
                    : '--',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: batteryColor,
                ),
              ),
            ],
          ),
          if (_batteryTemperature != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.thermostat_rounded,
                  size: 17,
                  color:
                      scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  'Batarya sıcaklığı',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTemperature(
                    _batteryTemperature,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cpuDetailsCard() {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.developer_board_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 9),
              const Text(
                'CPU detayları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cpuFrequencies.isEmpty)
            Text(
              'Frekans bilgisi alınamadı.',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            )
          else
            ...List.generate(
              _cpuFrequencies.length,
              (index) {
                final frequency =
                    _cpuFrequencies[index];

                final active =
                    index < _onlineCpuCount;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? scheme.primary
                              : scheme.onSurfaceVariant
                                  .withOpacity(0.30),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'CPU $index',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatFrequency(
                          frequency,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.device_thermostat_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: 9),
              const Text(
                'Termal bölgeler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_thermalZones.isEmpty)
            Text(
              'Termal sensör bilgisi alınamadı.',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            )
          else
            ..._thermalZones.entries.map(
              (entry) {
                final temperature =
                    entry.value;

                final temperatureColor =
                    temperature >= 55
                        ? scheme.error
                        : temperature >= 45
                            ? Colors.orange
                            : scheme.primary;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatTemperature(
                          temperature,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              temperatureColor,
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

  Widget _backgroundGlow() {
    if (!_isGlass) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -90,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 65,
                sigmaY: 65,
              ),
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withOpacity(
                    _isLightGlass ? 0.10 : 0.14,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 75,
                sigmaY: 75,
              ),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondary.withOpacity(
                    _isLightGlass ? 0.07 : 0.10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _isGlass
          ? Colors.transparent
          : scheme.surface,
      appBar: AppBar(
        title: const Text(
          'Sistem Monitörü',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _backgroundGlow(),
          RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                6,
                16,
                110,
              ),
              children: [
                _sectionTitle('Genel durum'),
                _usageCard(),
                _ramCard(),
                _batteryCard(),
                _sectionTitle('İşlemci'),
                _cpuDetailsCard(),
                _sectionTitle('Sıcaklık'),
                _thermalCard(),
                if (_onlineCpus.isNotEmpty) ...[
                  _sectionTitle('Aktif CPU listesi'),
                  _glassCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _onlineCpus
                          .map(
                            (cpu) => Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: scheme.primary
                                    .withOpacity(
                                  _isGlass
                                      ? 0.09
                                      : 0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                                border:
                                    Border.all(
                                  color: scheme.primary
                                      .withOpacity(
                                    0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                'CPU $cpu',
                                style:
                                    TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      scheme.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

