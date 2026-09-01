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

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo =
          DeviceInfoPlugin();

      final androidInfo =
          await deviceInfo.androidInfo;

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
        deviceModel = 'Alınamadı';
        manufacturer = 'Alınamadı';
        androidVersion = 'Alınamadı';
      });
    }
  }

  Future<void> _loadBatteryInfo() async {
    try {
      final battery = Battery();

      final level =
          await battery.batteryLevel;

      final state =
          await battery.batteryState;

      if (!mounted) return;

      String stateText;

      switch (state) {
        case BatteryState.charging:
          stateText = 'Şarj oluyor';
          break;

        case BatteryState.discharging:
          stateText = 'Şarj olmuyor';
          break;

        case BatteryState.full:
          stateText = 'Dolu';
          break;

        case BatteryState.connectedNotCharging:
          stateText =
              'Bağlı, şarj olmuyor';
          break;

        case BatteryState.unknown:
          stateText = 'Bilinmiyor';
          break;
      }

      setState(() {
        batteryLevel = '$level%';
        batteryState = stateText;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        batteryLevel = 'Alınamadı';
        batteryState = 'Alınamadı';
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
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Icon(
          icon,
          color: scheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 4,
          ),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _batteryWidget() {
    final scheme =
        Theme.of(context).colorScheme;

    final isGlass =
        widget.selectedStyle !=
            AppThemeStyle.normal;

    final isLight =
        widget.selectedStyle ==
            AppThemeStyle
                .liquidGlassLight;

    final parsed =
        int.tryParse(
          batteryLevel.replaceAll(
            '%',
            '',
          ),
        );

    final level =
        parsed == null
            ? 0
            : parsed.clamp(0, 100);

    final fill =
        level / 100.0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isGlass
            ? (isLight
                ? Colors.white
                    .withOpacity(0.52)
                : Colors.white
                    .withOpacity(0.07))
            : Theme.of(context)
                .colorScheme
                .surfaceContainer,
        borderRadius:
            BorderRadius.circular(22),
        border: isGlass
            ? Border.all(
                color: Colors.white
                    .withOpacity(
                  isLight
                      ? 0.72
                      : 0.18,
                ),
              )
            : null,
        boxShadow: isGlass
            ? [
                BoxShadow(
                  color: scheme.primary
                      .withOpacity(
                    isLight
                        ? 0.08
                        : 0.12,
                  ),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_full,
                color:
                    scheme.primary,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text(
                'Pil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                batteryLevel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      scheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  padding:
                      const EdgeInsets.all(3),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),
                    border: Border.all(
                      color: scheme
                          .onSurface
                          .withOpacity(
                        isLight
                            ? 0.45
                            : 0.55,
                      ),
                      width: 1.7,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      5,
                    ),
                    child: Align(
                      alignment:
                          Alignment.centerLeft,
                      child:
                          FractionallySizedBox(
                        widthFactor: fill,
                        child: Container(
                          decoration:
                              BoxDecoration(
                            color:
                                scheme.primary,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                            boxShadow: isGlass
                                ? [
                                    BoxShadow(
                                      color: scheme
                                          .primary
                                          .withOpacity(
                                        0.45,
                                      ),
                                      blurRadius:
                                          9,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                width: 6,
                height: 12,
                margin:
                    const EdgeInsets.only(
                  left: 2,
                ),
                decoration:
                    BoxDecoration(
                  color: scheme
                      .onSurface
                      .withOpacity(
                    0.55,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            batteryState,
            style: TextStyle(
              color:
                  scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Sistem'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          children: [
            Text(
              'Sistem Bilgileri',
              style:
                  Theme.of(context)
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

            _batteryWidget(),

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
