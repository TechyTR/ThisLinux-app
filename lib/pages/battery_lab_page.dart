import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryLabPage extends StatefulWidget {
  const BatteryLabPage({super.key});

  @override
  State<BatteryLabPage> createState() =>
      _BatteryLabPageState();
}

class _BatteryLabPageState
    extends State<BatteryLabPage> {
  final Battery _battery = Battery();

  int _level = 0;
  BatteryState _state =
      BatteryState.unknown;

  StreamSubscription<BatteryState>?
      _stateSubscription;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _loadBattery();

    try {
      _stateSubscription =
          _battery.onBatteryStateChanged
              .listen(
        (state) {
          if (!mounted) return;

          setState(() {
            _state = state;
          });

          _loadBatteryLevel();
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  Future<void> _loadBattery() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    await _loadBatteryLevel();

    try {
      final state =
          await _battery.batteryState;

      if (!mounted) return;

      setState(() {
        _state = state;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Pil durumu okunamadı.';
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadBatteryLevel() async {
    try {
      final level =
          await _battery.batteryLevel;

      if (!mounted) return;

      setState(() {
        _level =
            level.clamp(0, 100).toInt();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Pil seviyesi okunamadı.';
        });
      }
    }
  }

  String _stateText() {
    switch (_state) {
      case BatteryState.charging:
        return 'Şarj oluyor';

      case BatteryState.discharging:
        return 'Şarj olmuyor';

      case BatteryState.full:
        return 'Tam dolu';

      case BatteryState.connectedNotCharging:
        return 'Bağlı, şarj olmuyor';

      case BatteryState.unknown:
        return 'Bilinmiyor';
    }
  }

  IconData _stateIcon() {
    switch (_state) {
      case BatteryState.charging:
        return Icons.bolt;

      case BatteryState.discharging:
        return Icons.battery_std;

      case BatteryState.full:
        return Icons.battery_full;

      case BatteryState.connectedNotCharging:
        return Icons.power;

      case BatteryState.unknown:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
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
            const Text('Battery Lab'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBattery,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(
                      _stateIcon(),
                      size: 54,
                      color:
                          scheme.primary,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      '$_level%',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                scheme.primary,
                          ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      _stateText(),
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .battery_6_bar,
                          color:
                              scheme.primary,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Text(
                            'Pil seviyesi',
                          ),
                        ),
                        Text(
                          '$_level%',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    LinearProgressIndicator(
                      value:
                          _level / 100,
                      minHeight: 8,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  _stateIcon(),
                  color:
                      scheme.primary,
                ),
                title: const Text(
                  'Pil durumu',
                ),
                subtitle:
                    Text(_stateText()),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(
                height: 14,
              ),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber,
                    color:
                        scheme.error,
                  ),
                  title: const Text(
                    'Okuma uyarısı',
                  ),
                  subtitle:
                      Text(_error!),
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            if (_loading)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else
              Center(
                child: Text(
                  'Yenilemek için aşağı çekin.',
                  style: TextStyle(
                    color: scheme
                        .onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

