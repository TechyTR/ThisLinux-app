import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_version.dart';
import '../theme/app_theme.dart';

class SystemInfoPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const SystemInfoPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  AndroidDeviceInfo? _info;

  Map<String, dynamic> _nativeInfo = <String, dynamic>{};

  int _batteryLevel = -1;

  BatteryState _batteryState = BatteryState.unknown;

  bool _loading = true;

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;

      final battery = Battery();

      final level = await battery.batteryLevel;
      final state = await battery.batteryState;

      Map<String, dynamic> nativeInfo = <String, dynamic>{};

      try {
        final result =
            await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getDeviceInfo',
        );

        if (result != null) {
          nativeInfo = result.map(
            (key, value) => MapEntry(
              key.toString(),
              value,
            ),
          );
        }
      } catch (_) {
        nativeInfo = <String, dynamic>{};
      }

      if (!mounted) return;

      setState(() {
        _info = deviceInfo;
        _nativeInfo = nativeInfo;
        _batteryLevel = level;
        _batteryState = state;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return 'Bilinmiyor';
    }

    return text;
  }

  String _formatBytes(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;

    if (bytes <= 0) {
      return 'Bilinmiyor';
    }

    const units = [
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
    ];

    var size = bytes;
    var unit = 0;

    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    if (unit == 0) {
      return '${size.toStringAsFixed(0)} ${units[unit]}';
    }

    return '${size.toStringAsFixed(2)} ${units[unit]}';
  }

  String _formatRam(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final bytes = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;

    if (bytes <= 0) {
      return 'Bilinmiyor';
    }

    final gb = bytes / (1024 * 1024 * 1024);

    return '${gb.toStringAsFixed(2)} GB';
  }

  String _formatNumber(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    if (value is num) {
      return value.toStringAsFixed(0);
    }

    return _stringValue(value);
  }

  String _formatDensity(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final density = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());

    if (density == null) {
      return 'Bilinmiyor';
    }

    return '${density.toStringAsFixed(2)}x';
  }

  String _formatRefreshRate(dynamic value) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final rate = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());

    if (rate == null || rate <= 0) {
      return 'Bilinmiyor';
    }

    return '${rate.toStringAsFixed(1)} Hz';
  }

  String _batteryStateText() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Şarj oluyor';

      case BatteryState.discharging:
        return 'Şarj olmuyor';

      case BatteryState.full:
        return 'Dolu';

      case BatteryState.connectedNotCharging:
        return 'Bağlı, şarj olmuyor';

      case BatteryState.unknown:
        return 'Bilinmiyor';
    }
  }

  String _storageUsageText() {
    final total = _nativeInfo['total_storage'];
    final available = _nativeInfo['available_storage'];

    if (total == null || available == null) {
      return 'Bilinmiyor';
    }

    final totalBytes = total is num
        ? total.toDouble()
        : double.tryParse(total.toString()) ?? 0;

    final availableBytes = available is num
        ? available.toDouble()
        : double.tryParse(available.toString()) ?? 0;

    if (totalBytes <= 0) {
      return 'Bilinmiyor';
    }

    final used = totalBytes - availableBytes;

    final percentage =
        (used / totalBytes * 100).clamp(0, 100);

    return '${percentage.toStringAsFixed(1)}% kullanılıyor';
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
        top: 18,
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

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 22,
  }) {
    if (!_isGlass) {
      return Card(
        margin: const EdgeInsets.only(bottom: 9),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: ClipRRect(
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
                _isLightGlass ? 0.16 : 0.065,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.58 : 0.19,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _isLightGlass ? 0.06 : 0.18,
                  ),
                  blurRadius: 24,
                  spreadRadius: -7,
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

                // Üst kenardaki cam yansıması.
                Positioned(
                  left: 14,
                  right: 14,
                  top: 0,
                  height: 1.3,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(
                              _isLightGlass ? 0.78 : 0.35,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Sol üstten gelen hafif ışık.
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
                              _isLightGlass ? 0.08 : 0.035,
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(
                _isGlass ? 0.09 : 0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _summaryCard() {
    final scheme = Theme.of(context).colorScheme;

    final model = _stringValue(
      _nativeInfo['model'] ?? _info?.model,
    );

    final manufacturer = _stringValue(
      _nativeInfo['manufacturer'] ?? _info?.manufacturer,
    );

    final cpuCount = _nativeInfo['cpu_count'];
    final totalRam = _nativeInfo['total_ram'];

    final width = _nativeInfo['screen_width'];
    final height = _nativeInfo['screen_height'];

    return _glassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.09 : 0.12,
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
                  Icons.smartphone_rounded,
                  size: 31,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 15),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.memory_rounded,
                cpuCount == null
                    ? 'CPU bilinmiyor'
                    : '$cpuCount çekirdek',
              ),
              _chip(
                Icons.memory_outlined,
                _formatRam(totalRam),
              ),
              _chip(
                Icons.aspect_ratio_rounded,
                width == null || height == null
                    ? 'Ekran bilinmiyor'
                    : '$width × $height',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    IconData icon,
    String text,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(
          _isGlass ? 0.075 : 0.10,
        ),
        borderRadius: BorderRadius.circular(13),
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.25 : 0.09,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _batteryCard() {
    final scheme = Theme.of(context).colorScheme;

    final level = _batteryLevel.clamp(0, 100);
    final progress = level / 100.0;

    return _glassCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(
                    _isGlass ? 0.09 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _batteryState == BatteryState.charging
                      ? Icons.battery_charging_full_rounded
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
                      'Pil durumu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _batteryStateText(),
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
              value: progress,
              minHeight: 9,
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 60,
          sigmaY: 60,
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
    final info = _info;
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sistem Bilgisi',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final androidVersion = _stringValue(
      _nativeInfo['release'] ?? info?.version.release,
    );

    final sdk = _formatNumber(
      _nativeInfo['sdk_int'] ?? info?.version.sdkInt,
    );

    final securityPatch = _stringValue(
      _nativeInfo['security_patch'] ??
          info?.version.securityPatch,
    );

    final kernel = _stringValue(
      _nativeInfo['kernel_version'],
    );

    final board = _stringValue(
      _nativeInfo['board'] ?? info?.board,
    );

    final device = _stringValue(
      _nativeInfo['device'] ?? info?.device,
    );

    final product = _stringValue(
      _nativeInfo['product'] ?? info?.product,
    );

    final brand = _stringValue(
      _nativeInfo['brand'] ?? info?.brand,
    );

    final hardware = _stringValue(
      _nativeInfo['hardware'] ?? info?.hardware,
    );

    final fingerprint = _stringValue(
      _nativeInfo['fingerprint'] ?? info?.fingerprint,
    );

    final bootloader = _stringValue(
      _nativeInfo['bootloader'] ?? info?.bootloader,
    );

    final supportedAbis = _stringValue(
      _nativeInfo['supported_abis'] ??
          info?.supportedAbis.join(', '),
    );

    final socManufacturer = _stringValue(
      _nativeInfo['soc_manufacturer'],
    );

    final socModel = _stringValue(
      _nativeInfo['soc_model'],
    );

    final totalStorage = _nativeInfo['total_storage'];
    final availableStorage =
        _nativeInfo['available_storage'];

    final totalRam = _nativeInfo['total_ram'];

    final width = _nativeInfo['screen_width'];
    final height = _nativeInfo['screen_height'];

    final density = _nativeInfo['density'];
    final refreshRate = _nativeInfo['refresh_rate'];

    final storageText =
        '${_formatBytes(availableStorage)} boş / '
        '${_formatBytes(totalStorage)} toplam';

    final ramText = _formatRam(totalRam);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem Bilgisi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loadAll,
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
                  230,
                  _isLightGlass ? 0.10 : 0.075,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  const Alignment(1.10, -0.05),
                  250,
                  _isLightGlass ? 0.075 : 0.055,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _backgroundGlow(
                  const Alignment(0.30, 1.15),
                  230,
                  _isLightGlass ? 0.055 : 0.045,
                ),
              ),
            ),
          ],

          RefreshIndicator(
            onRefresh: _loadAll,
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
                _summaryCard(),

                _sectionTitle(
                  context,
                  'Pil',
                ),

                _batteryCard(),

                _sectionTitle(
                  context,
                  'Android',
                ),

                _infoCard(
                  icon: Icons.android_rounded,
                  title: 'Android sürümü',
                  value: androidVersion,
                ),

                _infoCard(
                  icon: Icons.numbers_rounded,
                  title: 'SDK',
                  value: sdk,
                ),

                _infoCard(
                  icon: Icons.security_rounded,
                  title: 'Güvenlik yaması',
                  value: securityPatch,
                ),

                _infoCard(
                  icon: Icons.terminal_rounded,
                  title: 'Kernel',
                  value: kernel,
                ),

                _sectionTitle(
                  context,
                  'Cihaz',
                ),

                _infoCard(
                  icon: Icons.badge_outlined,
                  title: 'Marka',
                  value: brand,
                ),

                _infoCard(
                  icon: Icons.phone_android_rounded,
                  title: 'Model',
                  value: _stringValue(
                    _nativeInfo['model'] ?? info?.model,
                  ),
                ),

                _infoCard(
                  icon: Icons.memory_rounded,
                  title: 'Donanım',
                  value: hardware,
                ),

                _infoCard(
                  icon: Icons.developer_board_rounded,
                  title: 'Board',
                  value: board,
                ),

                _infoCard(
                  icon: Icons.devices_other_rounded,
                  title: 'Device',
                  value: device,
                ),

                _infoCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product',
                  value: product,
                ),

                _infoCard(
                  icon: Icons.settings_input_component_rounded,
                  title: 'Bootloader',
                  value: bootloader,
                ),

                _sectionTitle(
                  context,
                  'İşlemci',
                ),

                _infoCard(
                  icon: Icons.memory_rounded,
                  title: 'Çekirdek sayısı',
                  value: _formatNumber(
                    _nativeInfo['cpu_count'],
                  ),
                ),

                _infoCard(
                  icon: Icons.developer_board_rounded,
                  title: 'SoC üreticisi',
                  value: socManufacturer,
                ),

                _infoCard(
                  icon: Icons.speed_rounded,
                  title: 'SoC modeli',
                  value: socModel,
                ),

                _infoCard(
                  icon: Icons.architecture_rounded,
                  title: 'Desteklenen ABI',
                  value: supportedAbis,
                ),

                _sectionTitle(
                  context,
                  'Bellek ve depolama',
                ),

                _infoCard(
                  icon: Icons.memory_outlined,
                  title: 'Toplam RAM',
                  value: ramText,
                ),

                _infoCard(
                  icon: Icons.storage_rounded,
                  title: 'Depolama',
                  value: storageText,
                ),

                _infoCard(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Depolama kullanımı',
                  value: _storageUsageText(),
                ),

                _sectionTitle(
                  context,
                  'Ekran',
                ),

                _infoCard(
                  icon: Icons.display_settings_rounded,
                  title: 'Çözünürlük',
                  value: width == null || height == null
                      ? 'Bilinmiyor'
                      : '$width × $height',
                ),

                _infoCard(
                  icon: Icons.density_medium_rounded,
                  title: 'Ekran yoğunluğu',
                  value: _formatDensity(density),
                ),

                _infoCard(
                  icon: Icons.speed_rounded,
                  title: 'Yenileme hızı',
                  value: _formatRefreshRate(
                    refreshRate,
                  ),
                ),

                _sectionTitle(
                  context,
                  'Sistem',
                ),

                _infoCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'Fingerprint',
                  value: fingerprint,
                ),

                _infoCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Stellar Center',
                  value: 'v${AppVersion.current}',
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Stellar Center • Android',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

