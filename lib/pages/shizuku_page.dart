import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ShizukuPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  const ShizukuPage({super.key, required this.selectedTheme, required this.selectedStyle});

  @override
  State<ShizukuPage> createState() => _ShizukuPageState();
}

class _ShizukuPageState extends State<ShizukuPage> {
  static const _channel = MethodChannel('org.test.thislinux/native');
  bool _installed = false;
  bool _running = false;
  bool _permissionGranted = false;
  bool _shizukuSu = false;
  bool _directSu = false;
  bool _loading = true;

  bool get _glass => widget.selectedStyle != AppThemeStyle.normal;
  bool get _light => widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<bool> _checkDirectSu() async {
    try {
      final process = await Process.run('su', const ['-c', 'id']).timeout(const Duration(seconds: 3));
      final output = '${process.stdout} ${process.stderr}';
      return process.exitCode == 0 && RegExp(r'uid=0\b').hasMatch(output);
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadStatus() async {
    bool installed = false;
    bool running = false;
    bool permission = false;
    bool shizukuSu = false;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getShizukuStatus');
      installed = result?['installed'] == true;
      running = result?['running'] == true;
      permission = result?['permissionGranted'] == true;
      shizukuSu = result?['suAvailable'] == true;
    } catch (_) {}
    final directSu = await _checkDirectSu();
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _running = running;
      _permissionGranted = permission;
      _shizukuSu = shizukuSu;
      _directSu = directSu;
      _loading = false;
    });
  }

  Future<void> _openShizuku() async {
    try { await _channel.invokeMethod('openShizuku'); } catch (_) {}
  }

  Future<void> _connect() async {
    try { await _channel.invokeMethod('connectShizuku'); } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _loadStatus();
  }

  Widget _card(Widget child) {
    if (!_glass) return Card(child: child);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_light ? .18 : .065),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(_light ? .50 : .16)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _status(String title, bool value, {String? detail}) {
    final color = value ? Colors.green : Theme.of(context).colorScheme.error;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(value ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: detail == null ? null : Text(detail),
      trailing: Text(value ? 'Aktif' : 'Yok', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('SU / Shizuku'), centerTitle: true, actions: [IconButton(onPressed: _loadStatus, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_directSu ? 'SU yetkisi aktif' : 'SU yetkisi algılanmadı', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_directSu ? 'Uygulama gerçek su komutu ile uid=0 doğrulaması yaptı.' : 'Root yöneticinizde bu uygulama için SU izninin verildiğini kontrol edin ve Yenileye basın.'),
            const SizedBox(height: 12),
            _status('Doğrudan SU', _directSu),
            _status('Shizuku kurulu', _installed),
            _status('Shizuku çalışıyor', _running),
            _status('Shizuku izni', _permissionGranted),
            _status('Shizuku UID 0', _shizukuSu),
          ])),
          const SizedBox(height: 12),
          if (!_directSu) ...[
            _card(const Text('SU görünmüyorsa root yöneticisinde uygulamanın süper kullanıcı isteğini onaylayın. Uygulama dosya yolu kontrolü yerine gerçek su -c id çıktısını doğrular.', style: TextStyle(height: 1.4))),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _openShizuku, icon: const Icon(Icons.open_in_new), label: const Text('Shizuku aç'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: _connect, icon: const Icon(Icons.link), label: const Text('Bağlan'))),
          ]),
        ],
      ),
    );
  }
}
