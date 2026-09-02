import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SystemInfoPage extends StatefulWidget {
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
  AndroidDeviceInfo? _info;

  int _batteryLevel = -1;

  BatteryState _batteryState =
      BatteryState.unknown;

  bool _loading = true;

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
      final deviceInfo =
          await DeviceInfoPlugin()
              .androidInfo;

      final battery =
          Battery();

      final level =
          await battery.batteryLevel;

      final state =
          await battery.batteryState;

      if (!mounted) return;

      setState(() {
        _info = deviceInfo;
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

  String _value(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Bilinmiyor';
    }

    return value;
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

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 10,
        top: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w700,
          color:
              scheme.onSurfaceVariant,
        ),
      ),
    );
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
        bottom: 9,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 5,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary
                .withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
          ),
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
          child: Text(
            value,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _batteryCard() {
    final scheme =
        Theme.of(context).colorScheme;

    final level =
        _batteryLevel.clamp(0, 100);

    final fill =
        level / 100.0;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
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
                        FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _batteryLevel < 0
                      ? '--'
                      : '$_batteryLevel%',
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
              height: 14,
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 28,
                    padding:
                        const EdgeInsets.all(3),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      border:
                          Border.all(
                        color: scheme
                            .onSurface
                            .withOpacity(0.45),
                        width: 1.6,
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 11,
                  margin:
                      const EdgeInsets.only(
                    left: 2,
                  ),
                  decoration:
                      BoxDecoration(
                    color: scheme
                        .onSurface
                        .withOpacity(0.5),
                    borderRadius:
                        BorderRadius.circular(
                      3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              _batteryStateText(),
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sistem Bilgileri',
          ),
          centerTitle: true,
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final info = _info;

    if (info == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Sistem Bilgileri',
          ),
          centerTitle: true,
        ),
        body: Center(
          child: FilledButton.icon(
            onPressed: _loadAll,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Tekrar dene',
            ),
          ),
        ),
      );
    }

    final version =
        info.version;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistem Bilgileri',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          children: [
            Text(
              'Cihaz',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_value(info.manufacturer)} '
              '${_value(info.model)}',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
              ),
            ),

            _sectionTitle(
              context,
              'Donanım',
            ),

            _infoCard(
              icon: Icons.phone_android,
              title: 'Model',
              value: _value(info.model),
            ),

            _infoCard(
              icon: Icons.business,
              title: 'Üretici',
              value:
                  _value(info.manufacturer),
            ),

            _infoCard(
              icon: Icons.devices,
              title: 'Marka',
              value: _value(info.brand),
            ),

            _infoCard(
              icon: Icons.memory,
              title: 'Donanım',
              value:
                  _value(info.hardware),
            ),

            _infoCard(
              icon: Icons.developer_board,
              title: 'Board',
              value:
                  _value(info.board),
            ),

            _infoCard(
              icon: Icons.smartphone,
              title: 'Cihaz kodu',
              value:
                  _value(info.device),
            ),

            _infoCard(
              icon: Icons.inventory_2,
              title: 'Ürün',
              value:
                  _value(info.product),
            ),

            _sectionTitle(
              context,
              'Android',
            ),

            _infoCard(
              icon: Icons.android,
              title: 'Android',
              value:
                  'Android ${_value(version.release)}',
            ),

            _infoCard(
              icon: Icons.numbers,
              title: 'SDK',
              value:
                  '${version.sdkInt}',
            ),

            _infoCard(
              icon: Icons.build,
              title: 'Build',
              value:
                  _value(version.incremental),
            ),

            _infoCard(
              icon: Icons.security,
              title: 'Güvenlik yaması',
              value:
                  _value(version.securityPatch),
            ),

            _infoCard(
              icon: Icons.settings,
              title: 'Base OS',
              value:
                  _value(version.baseOS),
            ),

            _infoCard(
              icon: Icons.update,
              title: 'Preview SDK',
              value:
                  '${version.previewSdkInt}',
            ),

            _sectionTitle(
              context,
              'Uygulama ortamı',
            ),

            _infoCard(
              icon: Icons.api,
              title: 'API seviyesi',
              value:
                  '${version.sdkInt}',
            ),

            _infoCard(
              icon: Icons.architecture,
              title: 'Desteklenen ABI',
              value:
                  info.supportedAbis
                      .join(', '),
            ),

            _infoCard(
              icon: Icons.extension,
              title: '32-bit ABI',
              value:
                  info.supported32BitAbis
                      .join(', '),
            ),

            _infoCard(
              icon: Icons.extension_outlined,
              title: '64-bit ABI',
              value:
                  info.supported64BitAbis
                      .join(', '),
            ),

            _sectionTitle(
              context,
              'Pil',
            ),

            _batteryCard(),

            _sectionTitle(
              context,
              'Stellar Center',
            ),

            _infoCard(
              icon:
                  Icons.auto_awesome,
              title: 'Sürüm',
              value: '2.5',
            ),

            _infoCard(
              icon: Icons.linux,
              title: 'Platform',
              value:
                  'Linux / Android',
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Not: Donanım kimliği, IMEI ve seri '
              'numarası gibi hassas tanımlayıcılar '
              'gösterilmez.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
