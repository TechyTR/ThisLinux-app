import 'dart:async';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_version.dart';
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

  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  int _batteryLevel = -1;
  BatteryState _batteryState = BatteryState.unknown;

  bool _loading = true;

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
          (key, value) => MapEntry(
            key.toString(),
            value,
          ),
        );

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
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
    if (value == null) {
      return 'Bilinmiyor';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return 'Bilinmiyor';
    }

    return text;
  }

  String _ram(dynamic value) {
    if (value == null) {
      return '?';
    }

    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;

    if (bytes <= 0) {
      return '?';
    }

    final gb = bytes / (1024 * 1024 * 1024);

    return '${gb.toStringAsFixed(1)} GB';
  }

  String _storage(dynamic value) {
    if (value == null) {
      return '?';
    }

    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;

    if (bytes <= 0) {
      return '?';
    }

    final gb = bytes / (1024 * 1024 * 1024);

    return '${gb.toStringAsFixed(1)} GB';
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 24,
    Color? tint,
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

    final baseTint = tint ?? Colors.white;

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
            color: baseTint.withOpacity(
              _isLightGlass ? 0.18 : 0.075,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                _isLightGlass ? 0.62 : 0.22,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isLightGlass ? 0.07 : 0.20,
                ),
                blurRadius: 26,
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

              // Üst cam yansıması.
              Positioned(
                left: 14,
                right: 14,
                top: 0,
                height: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(
                            _isLightGlass ? 0.80 : 0.38,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // İç taraftaki hafif ışık kırılması.
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
                            _isLightGlass ? 0.12 : 0.055,
                          ),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Çok hafif tema renkli cam yansıması.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: RadialGradient(
                        center: const Alignment(-0.8, -1),
                        radius: 1.25,
                        colors: [
                          scheme.primary.withOpacity(
                            _isLightGlass ? 0.075 : 0.055,
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

  Widget _quickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final content = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(
                  _isGlass ? 0.10 : 0.12,
                ),
                borderRadius: BorderRadius.circular(15),
                border: _isGlass
                    ? Border.all(
                        color: Colors.white.withOpacity(
                          _isLightGlass ? 0.32 : 0.10,
                        ),
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: scheme.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
    );

    if (!_isGlass) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return _glassCard(
      padding: EdgeInsets.zero,
      child: content,
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(
                _isGlass ? 0.09 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final model = _value(
      _deviceInfo['model'],
    );

    final manufacturer = _value(
      _deviceInfo['manufacturer'],
    );

    final androidVersion = _value(
      _deviceInfo['release'],
    );

    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(
                _isGlass ? 0.09 : 0.12,
              ),
              borderRadius: BorderRadius.circular(20),
              border: _isGlass
                  ? Border.all(
                      color: Colors.white.withOpacity(
                        _isLightGlass ? 0.30 : 0.10,
                      ),
                    )
                  : null,
            ),
            child: Icon(
              Icons.smartphone_rounded,
              size: 32,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  manufacturer,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Android $androidVersion',
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

  Widget _batteryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final level =
        _batteryLevel < 0 ? 0 : _batteryLevel.clamp(0, 100);

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.09 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _batteryIcon(),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: level / 100,
              minHeight: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(
              _isGlass ? 0.11 : 0.18,
            ),
            scheme.primary.withOpacity(
              _isGlass ? 0.025 : 0.04,
            ),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Stellar Center',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Cihazını kontrol et, sistemini izle.',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'v${AppVersion.current}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/icon.png',
            width: 62,
            height: 62,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Icon(
                Icons.auto_awesome_rounded,
                size: 55,
                color: scheme.primary,
              );
            },
          ),
        ],
      ),
    );

    if (!_isGlass) {
      return Card(
        child: content,
      );
    }

    return _glassCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: content,
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _backgroundGlow(
    BuildContext context,
    Alignment alignment,
    double size,
    double opacity,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 55,
          sigmaY: 55,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withOpacity(opacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cpuCount = _deviceInfo['cpu_count'];
    final totalRam = _deviceInfo['total_ram'];

    final availableStorage =
        _deviceInfo['available_storage'];

    final totalStorage =
        _deviceInfo['total_storage'];

    final width = _deviceInfo['screen_width'];
    final height = _deviceInfo['screen_height'];

    final usedStorage =
        totalStorage is num &&
                availableStorage is num
            ? totalStorage - availableStorage
            : null;

    final storageText = usedStorage != null &&
            totalStorage is num
        ? '${_storage(usedStorage)} / ${_storage(totalStorage)}'
        : '?';

    final resolutionText =
        width != null && height != null
            ? '$width × $height'
            : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stellar Center',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () {
              _loadDeviceInfo();
              _loadBattery();
            },
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
                  context,
                  const Alignment(-1.15, -0.85),
                  230,
                  _isLightGlass ? 0.11 : 0.08,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  context,
                  const Alignment(1.15, 0.05),
                  260,
                  _isLightGlass ? 0.08 : 0.065,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  context,
                  const Alignment(0.35, 1.15),
                  220,
                  _isLightGlass ? 0.065 : 0.055,
                ),
              ),
            ),
          ],

          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadDeviceInfo(),
                _loadBattery(),
              ]);
            },
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                28,
              ),
              children: [
                _welcomeCard(context),

                const SizedBox(height: 10),

                _deviceHeader(context),

                const SizedBox(height: 10),

                _batteryCard(context),

                const SizedBox(height: 18),

                _sectionTitle(
                  context,
                  'Sistem özeti',
                ),

                const SizedBox(height: 8),

                if (_loading)
                  _glassCard(
                    child: const SizedBox(
                      height: 70,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                    childAspectRatio: 1.35,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      _statCard(
                        context: context,
                        icon: Icons.memory_rounded,
                        title: 'İşlemci',
                        value: cpuCount == null
                            ? '? çekirdek'
                            : '$cpuCount çekirdek',
                      ),
                      _statCard(
                        context: context,
                        icon: Icons.memory_outlined,
                        title: 'RAM',
                        value: _ram(totalRam),
                      ),
                      _statCard(
                        context: context,
                        icon: Icons.storage_rounded,
                        title: 'Depolama',
                        value: storageText,
                      ),
                      _statCard(
                        context: context,
                        icon: Icons.display_settings_rounded,
                        title: 'Ekran',
                        value: resolutionText,
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                _sectionTitle(
                  context,
                  'Hızlı erişim',
                ),

                const SizedBox(height: 8),

                _quickAction(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'Sistem bilgisi',
                  subtitle:
                      'Cihazın tüm teknik bilgilerini görüntüle',
                  onTap: widget.onSystemInfo,
                ),

                const SizedBox(height: 9),

                _quickAction(
                  context: context,
                  icon: Icons.monitor_heart_outlined,
                  title: 'Sistem monitörü',
                  subtitle:
                      'CPU, RAM, pil ve sıcaklıkları izle',
                  onTap: widget.onSystemMonitor,
                ),

                const SizedBox(height: 9),

                _quickAction(
                  context: context,
                  icon: Icons.notes_rounded,
                  title: 'Notlar',
                  subtitle:
                      'Kendi notlarını oluştur ve yönet',
                  onTap: widget.onNotes,
                ),

                const SizedBox(height: 9),

                _quickAction(
                  context: context,
                  icon: Icons.apps_rounded,
                  title: 'Uygulama',
                  subtitle:
                      'Stellar Center ayarları ve sürüm bilgisi',
                  onTap: widget.onAppInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

