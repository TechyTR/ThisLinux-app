import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SystemInfoPage
    extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(
    AppThemeColor,
  ) onThemeChanged;

  final Future<void> Function(
    AppThemeStyle,
  ) onStyleChanged;

  const SystemInfoPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<SystemInfoPage> createState() =>
      _SystemInfoPageState();
}

class _SystemInfoPageState
    extends State<SystemInfoPage> {
  String deviceModel =
      'Yükleniyor...';

  String manufacturer =
      'Yükleniyor...';

  String androidVersion =
      'Yükleniyor...';

  String batteryLevel =
      'Yükleniyor...';

  String batteryState =
      'Yükleniyor...';

  @override
  void initState() {
    super.initState();

    _loadDeviceInfo();
    _loadBatteryInfo();
  }

  Future<void>
      _loadDeviceInfo() async {
    try {
      final deviceInfo =
          DeviceInfoPlugin();

      final androidInfo =
          await deviceInfo
              .androidInfo;

      if (!mounted) return;

      setState(() {
        deviceModel =
            androidInfo.model;

        manufacturer =
            androidInfo.manufacturer;

        androidVersion =
            'Android ${androidInfo.version.release}';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        deviceModel =
            'Alınamadı';

        manufacturer =
            'Alınamadı';

        androidVersion =
            'Alınamadı';
      });
    }
  }

  Future<void>
      _loadBatteryInfo() async {
    try {
      final battery =
          Battery();

      final level =
          await battery
              .batteryLevel;

      final state =
          await battery
              .batteryState;

      if (!mounted) return;

      setState(() {
        batteryLevel =
            '%$level';

        switch (state) {
          case BatteryState
              .charging:
            batteryState =
                'Şarj oluyor';
            break;

          case BatteryState
              .discharging:
            batteryState =
                'Şarj olmuyor';
            break;

          case BatteryState.full:
            batteryState =
                'Dolu';
            break;

          case BatteryState
              .connectedNotCharging:
            batteryState =
                'Bağlı, şarj olmuyor';
            break;

          case BatteryState.unknown:
            batteryState =
                'Bilinmiyor';
            break;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        batteryLevel =
            'Alınamadı';

        batteryState =
            'Alınamadı';
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadDeviceInfo(),
      _loadBatteryInfo(),
    ]);
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Icon(
          icon,
          color: scheme.primary,
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets
                  .only(
            top: 4,
          ),
          child: Text(
            value,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem',
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(
            20,
          ),
          children: [
            Text(
              'Sistem Bilgileri',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Cihazınız hakkında temel bilgiler',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            _infoCard(
              icon:
                  Icons.smartphone,
              title: 'Cihaz',
              value:
                  deviceModel,
            ),
            _infoCard(
              icon: Icons.business,
              title: 'Üretici',
              value:
                  manufacturer,
            ),
            _infoCard(
              icon: Icons.android,
              title:
                  'Android Sürümü',
              value:
                  androidVersion,
            ),
            _infoCard(
              icon:
                  Icons.battery_full,
              title: 'Pil',
              value:
                  batteryLevel,
            ),
            _infoCard(
              icon: Icons.bolt,
              title:
                  'Şarj Durumu',
              value:
                  batteryState,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Yenilemek için ekranı aşağı çekin.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
