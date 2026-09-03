import 'dart:async';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/shizuku_page.dart';
import '../pages/stellar_secure_page.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  final VoidCallback? onSystemInfo;
  final VoidCallback? onSystemMonitor;
  final VoidCallback? onNotes;
  final VoidCallback? onAppInfo;

  const DashboardPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
    this.onSystemInfo,
    this.onSystemMonitor,
    this.onNotes,
    this.onAppInfo,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  Map<String, dynamic> _deviceInfo = {};

  int _batteryLevel = -1;
  BatteryState _batteryState = BatteryState.unknown;

  Timer? _batteryTimer;

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();

    _loadDeviceInfo();
    _loadBattery();

    _batteryTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadBattery(),
    );
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );

      if (!mounted || result == null) return;

      setState(() {
        _deviceInfo = result.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      });
    } catch (_) {}
  }

  Future<void> _loadBattery() async {
    try {
      final battery = Battery();

      final level = await battery.batteryLevel;
      final state = await battery.batteryState;

      if (!mounted) return;

      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
    } catch (_) {}
  }

  String _value(dynamic value) {
    if (value == null) return 'Bilinmiyor';

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return 'Bilinmiyor';
    }

    return text;
  }

  String _ram(dynamic value) {
    if (value == null) return '--';

    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;

    if (bytes <= 0) return '--';

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _batteryText() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Şarj oluyor';
      case BatteryState.full:
        return 'Tam dolu';
      case BatteryState.connectedNotCharging:
        return 'Bağlı';
      case BatteryState.discharging:
        return 'Pil kullanılıyor';
      case BatteryState.unknown:
        return 'Bilinmiyor';
    }
  }

  IconData _batteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full_rounded;
    }

    if (_batteryLevel >= 75) {
      return Icons.battery_full_rounded;
    }

    if (_batteryLevel >= 40) {
      return Icons.battery_5_bar_rounded;
    }

    if (_batteryLevel >= 15) {
      return Icons.battery_3_bar_rounded;
    }

    return Icons.battery_1_bar_rounded;
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 24,
  }) {
    if (!_isGlass) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(
              _isLightGlass ? 0.17 : 0.07,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                _isLightGlass ? 0.60 : 0.21,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isLightGlass ? 0.07 : 0.20,
                ),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 10),
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
                left: 16,
                right: 16,
                top: 0,
                height: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(
                            _isLightGlass ? 0.82 : 0.38,
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
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(
                            _isLightGlass ? 0.10 : 0.04,
                          ),
                          Colors.transparent,
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
                      borderRadius: BorderRadius.circular(radius),
                      gradient: RadialGradient(
                        center: const Alignment(-0.8, -1),
                        radius: 1.2,
                        colors: [
                          scheme.primary.withOpacity(
                            _isLightGlass ? 0.07 : 0.05,
                          ),
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
    );
  }

  Widget _securityCard() {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StellarSecurePage(
                selectedTheme: widget.selectedTheme,
                selectedStyle: widget.selectedStyle,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.11 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: _isGlass
                      ? Border.all(
                          color: Colors.white.withOpacity(
                            _isLightGlass ? 0.28 : 0.10,
                          ),
                        )
                      : null,
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: scheme.primary,
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Güvenlik denetlemesi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Stellar Secure ile telefonunuzun güvenliğini kontrol edin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shizukuCard() {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShizukuPage(
                selectedTheme: widget.selectedTheme,
                selectedStyle: widget.selectedStyle,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.11 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: _isGlass
                      ? Border.all(
                          color: Colors.white.withOpacity(
                            _isLightGlass ? 0.28 : 0.10,
                          ),
                        )
                      : null,
                ),
                child: Icon(
                  Icons.cable_rounded,
                  color: scheme.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shizuku bağlantısı',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gelişmiş Android yetkilerini ve bağlantı durumunu yönetin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceCard() {
    final scheme = Theme.of(context).colorScheme;

    final model = _value(_deviceInfo['model']);
    final manufacturer = _value(_deviceInfo['manufacturer']);
    final android = _value(_deviceInfo['release']);
    final ram = _ram(_deviceInfo['total_ram']);

    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(
                _isGlass ? 0.10 : 0.13,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.smartphone_rounded,
              size: 33,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  manufacturer,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Android $android • $ram RAM',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _batteryCard() {
    final scheme = Theme.of(context).colorScheme;

    final value = _batteryLevel < 0
        ? 0.0
        : (_batteryLevel.clamp(0, 100) / 100).toDouble();

    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _batteryIcon(),
                color: scheme.primary,
                size: 30,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pil durumu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _batteryText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
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
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow() {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(
                  _isGlass ? 0.07 : 0.035,
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(
                  _isGlass ? 0.045 : 0.02,
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

    return Stack(
      children: [
        _backgroundGlow(),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadDeviceInfo(),
                _loadBattery(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                120,
              ),
              children: [
                const Text(
                  'Stellar Secure',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Cihazınızın güvenliği ve gelişmiş sistem erişimi',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Güvenlik',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _securityCard(),
                const SizedBox(height: 12),
                const Text(
                  'Gelişmiş bağlantı',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _shizukuCard(),
                const SizedBox(height: 24),
                const Text(
                  'Cihaz',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _deviceCard(),
                const SizedBox(height: 12),
                _batteryCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
