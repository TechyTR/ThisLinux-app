import 'dart:async';

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

  Widget _quickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
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
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: scheme.primary,
              size: 23,
            ),
            const SizedBox(height: 13),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _batteryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final level =
        _batteryLevel < 0 ? 0 : _batteryLevel.clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
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
      ),
    );
  }

  Widget _welcomeCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withOpacity(0.18),
              scheme.primary.withOpacity(0.04),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cpuCount =
        _deviceInfo['cpu_count'];

    final totalRam =
        _deviceInfo['total_ram'];

    final availableStorage =
        _deviceInfo['available_storage'];

    final totalStorage =
        _deviceInfo['total_storage'];

    final width =
        _deviceInfo['screen_width'];

    final height =
        _deviceInfo['screen_height'];

    final usedStorage =
        totalStorage is num &&
                availableStorage is num
            ? totalStorage - availableStorage
            : null;

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
      body: RefreshIndicator(
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

            Text(
              'Sistem özeti',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            if (_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(25),
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
                    value: usedStorage == null ||
                            totalStorage == null
                        ? '?'
                        : '${_storage(usedStorage)} / '
                            '${_storage(totalStorage)}',
                  ),
                  _statCard(
                    context: context,
                    icon: Icons.display_settings_rounded,
                    title: 'Ekran',
                    value: width == null ||
                            height == null
                        ? '?'
                        : '$width × $height',
                  ),
                ],
              ),

            const SizedBox(height: 18),

            Text(
              'Hızlı erişim',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            _quickAction(
              context: context,
              icon: Icons.info_outline_rounded,
              title: 'Sistem Bilgileri',
              subtitle:
                  'Cihazın tüm teknik ayrıntılarını görüntüle',
              onTap: widget.onSystemInfo,
            ),

            _quickAction(
              context: context,
              icon: Icons.speed_rounded,
              title: 'Sistem Monitörü',
              subtitle:
                  'CPU, RAM, pil ve sıcaklıkları gerçek zamanlı izle',
              onTap: widget.onSystemMonitor,
            ),

            _quickAction(
              context: context,
              icon: Icons.notes_rounded,
              title: 'Notlar',
              subtitle:
                  'Kişisel notlarını görüntüle ve düzenle',
              onTap: widget.onNotes,
            ),

            _quickAction(
              context: context,
              icon: Icons.settings_suggest_rounded,
              title: 'Uygulama',
              subtitle:
                  'Stellar Center ayarları ve uygulama bilgileri',
              onTap: widget.onAppInfo,
            ),
          ],
        ),
      ),
    );
  }
}
