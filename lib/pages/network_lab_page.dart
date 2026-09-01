import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkLabPage extends StatefulWidget {
  const NetworkLabPage({
    super.key,
  });

  @override
  State<NetworkLabPage> createState() =>
      _NetworkLabPageState();
}

class _NetworkLabPageState
    extends State<NetworkLabPage> {
  bool _testing = false;

  int? _latency;
  int? _statusCode;

  String _status =
      'Test henüz yapılmadı';

  DateTime? _lastTest;

  Future<void> _runTest() async {
    if (_testing) return;

    setState(() {
      _testing = true;
      _latency = null;
      _statusCode = null;
      _status = 'Bağlantı test ediliyor...';
    });

    final stopwatch = Stopwatch()
      ..start();

    try {
      final response =
          await http
              .get(
                Uri.parse(
                  'https://www.google.com/generate_204',
                ),
              )
              .timeout(
                const Duration(
                  seconds: 5,
                ),
              );

      stopwatch.stop();

      if (!mounted) return;

      setState(() {
        _latency =
            stopwatch.elapsedMilliseconds;
        _statusCode =
            response.statusCode;
        _status =
            response.statusCode == 204
                ? 'Bağlantı başarılı'
                : 'Sunucu yanıt verdi';
        _lastTest = DateTime.now();
        _testing = false;
      });
    } catch (_) {
      stopwatch.stop();

      if (!mounted) return;

      setState(() {
        _latency =
            stopwatch.elapsedMilliseconds;
        _status =
            'Bağlantı başarısız';
        _lastTest = DateTime.now();
        _testing = false;
      });
    }
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
        leading: Icon(
          icon,
          color: scheme.primary,
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _latencyText() {
    if (_latency == null) {
      return '--';
    }

    return '${_latency} ms';
  }

  String _statusCodeText() {
    if (_statusCode == null) {
      return '--';
    }

    return '$_statusCode';
  }

  String _lastTestText() {
    if (_lastTest == null) {
      return '--';
    }

    final hour =
        _lastTest!.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        _lastTest!.minute
            .toString()
            .padLeft(2, '0');

    final second =
        _lastTest!.second
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute:$second';
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
            const Text('Network Lab'),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.network_check,
                    size: 52,
                    color:
                        scheme.primary,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Google bağlantısı üzerinden '
                    'gerçek ağ testi',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: scheme
                          .onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _infoCard(
            icon: Icons.speed,
            title: 'Gecikme',
            value: _latencyText(),
          ),

          _infoCard(
            icon: Icons.http,
            title: 'HTTP Durumu',
            value: _statusCodeText(),
          ),

          _infoCard(
            icon: Icons.schedule,
            title: 'Son Test',
            value: _lastTestText(),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  _testing
                      ? null
                      : _runTest,
              icon: const Icon(
                Icons.network_check,
              ),
              label: Text(
                _testing
                    ? 'Test yapılıyor...'
                    : 'Bağlantıyı Test Et',
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            'Gecikme değeri internet bağlantısının '
            'anlık durumuna göre değişebilir.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
