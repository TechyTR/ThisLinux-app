import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorLabPage extends StatefulWidget {
  const SensorLabPage({
    super.key,
  });

  @override
  State<SensorLabPage> createState() =>
      _SensorLabPageState();
}

class _SensorLabPageState
    extends State<SensorLabPage> {
  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription;

  StreamSubscription<GyroscopeEvent>?
      _gyroscopeSubscription;

  StreamSubscription<MagnetometerEvent>?
      _magnetometerSubscription;

  StreamSubscription<UserAccelerometerEvent>?
      _userAccelerometerSubscription;

  AccelerometerEvent? _accelerometer;
  GyroscopeEvent? _gyroscope;
  MagnetometerEvent? _magnetometer;
  UserAccelerometerEvent?
      _userAccelerometer;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    _accelerometerSubscription =
        accelerometerEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _accelerometer = event;
        });
      },
      onError: (_) {},
    );

    _gyroscopeSubscription =
        gyroscopeEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _gyroscope = event;
        });
      },
      onError: (_) {},
    );

    _magnetometerSubscription =
        magnetometerEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _magnetometer = event;
        });
      },
      onError: (_) {},
    );

    _userAccelerometerSubscription =
        userAccelerometerEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _userAccelerometer = event;
        });
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();

    super.dispose();
  }

  String _value(double? value) {
    if (value == null) {
      return '--';
    }

    return value.toStringAsFixed(3);
  }

  Widget _sensorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> values,
  }) {
    final scheme =
        Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
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
                  icon,
                  color: scheme.primary,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
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
              height: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: _axis(
                    'X',
                    values[0],
                  ),
                ),
                Expanded(
                  child: _axis(
                    'Y',
                    values[1],
                  ),
                ),
                Expanded(
                  child: _axis(
                    'Z',
                    values[2],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _axis(
    String axis,
    String value,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          axis,
          style: TextStyle(
            color:
                scheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('SensorLab'),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          _sensorCard(
            icon: Icons.explore,
            title: 'Accelerometer',
            subtitle:
                'Cihazın ivme değerleri',
            values: [
              _value(
                _accelerometer?.x,
              ),
              _value(
                _accelerometer?.y,
              ),
              _value(
                _accelerometer?.z,
              ),
            ],
          ),

          _sensorCard(
            icon: Icons.screen_rotation,
            title: 'Gyroscope',
            subtitle:
                'Dönüş hızı değerleri',
            values: [
              _value(
                _gyroscope?.x,
              ),
              _value(
                _gyroscope?.y,
              ),
              _value(
                _gyroscope?.z,
              ),
            ],
          ),

          _sensorCard(
            icon: Icons.explore_outlined,
            title: 'Magnetometer',
            subtitle:
                'Manyetik alan değerleri',
            values: [
              _value(
                _magnetometer?.x,
              ),
              _value(
                _magnetometer?.y,
              ),
              _value(
                _magnetometer?.z,
              ),
            ],
          ),

          _sensorCard(
            icon: Icons.vibration,
            title: 'User Accelerometer',
            subtitle:
                'Yerçekimi çıkarılmış ivme',
            values: [
              _value(
                _userAccelerometer?.x,
              ),
              _value(
                _userAccelerometer?.y,
              ),
              _value(
                _userAccelerometer?.z,
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Değerler gerçek zamanlı olarak '
            'sensörlerden okunur.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
