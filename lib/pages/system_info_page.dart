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
  static const MethodChannel _channel =
      MethodChannel(
    'org.test.thislinux/native',
  );

  AndroidDeviceInfo? _info;

  Map<String, dynamic> _nativeInfo =
      <String, dynamic>{};

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
          await DeviceInfoPlugin().androidInfo;

      final battery = Battery();

      final level =
          await battery.batteryLevel;

      final state =
          await battery.batteryState;

      Map<String, dynamic> nativeInfo =
          <String, dynamic>{};

      try {
        final result =
            await _channel.invokeMethod<
                Map<dynamic, dynamic>>(
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

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text == 'null') {
      return 'Bilinmiyor';
    }

    return text;
  }

  String _formatBytes(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final bytes =
        value is num
            ? value.toDouble()
            : double.tryParse(
                  value.toString(),
                ) ??
                0;

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

    while (size >= 1024 &&
        unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    if (unit == 0) {
      return '${size.toStringAsFixed(0)} ${units[unit]}';
    }

    return '${size.toStringAsFixed(2)} ${units[unit]}';
  }

  String _formatRam(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final bytes =
        value is num
            ? value.toDouble()
            : double.tryParse(
                  value.toString(),
                ) ??
                0;

    if (bytes <= 0) {
      return 'Bilinmiyor';
    }

    final gb =
        bytes /
        (1024 * 1024 * 1024);

    return '${gb.toStringAsFixed(2)} GB';
  }

  String _formatNumber(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    if (value is num) {
      return value
          .toStringAsFixed(0);
    }

    return _stringValue(value);
  }

  String _formatDensity(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final density =
        value is num
            ? value.toDouble()
            : double.tryParse(
                  value.toString(),
                );

    if (density == null) {
      return 'Bilinmiyor';
    }

    return '${density.toStringAsFixed(2)}x';
  }

  String _formatRefreshRate(
    dynamic value,
  ) {
    if (value == null) {
      return 'Bilinmiyor';
    }

    final rate =
        value is num
            ? value.toDouble()
            : double.tryParse(
                  value.toString(),
                );

    if (rate == null ||
        rate <= 0) {
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
    final total =
        _nativeInfo['total_storage'];

    final available =
        _nativeInfo['available_storage'];

    if (total == null ||
        available == null) {
      return 'Bilinmiyor';
    }

    final totalBytes =
        total is num
            ? total.toDouble()
            : double.tryParse(
                  total.toString(),
                ) ??
                0;

    final availableBytes =
        available is num
            ? available.toDouble()
            : double.tryParse(
                  available.toString(),
                ) ??
                0;

    final used =
        totalBytes - availableBytes;

    if (totalBytes <= 0) {
      return 'Bilinmiyor';
    }

    final percentage =
        (used / totalBytes * 100)
            .clamp(0, 100);

    return '${percentage.toStringAsFixed(1)}% kullanılıyor';
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
        top: 18,
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
          decoration:
              BoxDecoration(
            color: scheme.primary
                .withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
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
            maxLines: 4,
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
                            .withOpacity(
                          0.45,
                        ),
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
                                  BorderRadius.circular(
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
                        .withOpacity(
                      0.5,
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

  Widget _summaryCard(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    final model = _stringValue(
      _nativeInfo['model'] ??
          _info?.model,
    );

    final manufacturer =
        _stringValue(
      _nativeInfo['manufacturer'] ??
          _info?.manufacturer,
    );

    final cpuCount =
        _nativeInfo['cpu_count'];

    final totalRam =
        _nativeInfo['total_ram'];

    final width =
        _nativeInfo['screen_width'];

    final height =
        _nativeInfo['screen_height'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration:
                      BoxDecoration(
                    color: scheme.primary
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: 30,
                    color:
                        scheme.primary,
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        model,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        manufacturer,
                        style: TextStyle(
                          color: scheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context,
                  Icons.memory,
                  cpuCount == null
                      ? 'CPU ? çekirdek'
                      : '$cpuCount çekirdek',
                ),
                _chip(
                  context,
                  Icons.memory_outlined,
                  _formatRam(
                    totalRam,
                  ),
                ),
                _chip(
                  context,
                  Icons.aspect_ratio,
                  width == null ||
                          height == null
                      ? 'Ekran bilinmiyor'
                      : '$width × $height',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

   
