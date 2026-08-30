import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SystemInfoPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Future<void> Function(AppThemeColor) onThemeChanged;

  const SystemInfoPage({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  String deviceModel = 'Yükleniyor...';
  String batteryLevel = 'Yükleniyor...';
  String batteryState = 'Yükleniyor...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadBatteryInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (!mounted) return;

      setState(() {
        deviceModel =
            '${androidInfo.manufacturer} ${androidInfo.model}';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        deviceModel = 'Alınamadı';
      });
    }
  }

  Future<void> _loadBatteryInfo() async {
    try {
      final battery = Battery();

      final level = await battery.batteryLevel;
      final state = await battery.batteryState;

      if (!mounted) return;

      setState(() {
        batteryLevel = '%$level';

        batteryState = switch (state) {
          BatteryState.charging => 'Şarj oluyor',
          BatteryState.discharging => 'Şarj olmuyor',
          BatteryState.full => 'Dolu',
          BatteryState.connectedNotCharging => 'Bağlı, şarj olmuyor',
          BatteryState.unknown => 'Bilinmiyor',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        batteryLevel = 'Alınamadı';
        batteryState = 'Alınamadı';
      });
    }
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: scheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Sistem',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        _infoCard(
          context,
          Icons.smartphone,
          'Cihaz Modeli',
          deviceModel,
        ),

        _infoCard(
          context,
          Icons.battery_full,
          'Pil Yüzdesi',
          batteryLevel,
        ),

        _infoCard(
          context,
          Icons.bolt,
          'Şarj Durumu',
          batteryState,
        ),
      ],
    );
  }
}
