import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class SystemMonitorPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;
  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const SystemMonitorPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  static const _channel = MethodChannel('org.test.thislinux/native');

  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  double _cpu = 0;
  double _ramTotal = 0;
  double _ramUsed = 0;
  double _ramAvailable = 0;
  int _battery = -1;
  double? _batteryTemp;
  String _batteryState = 'Bilinmiyor';
  String _batterySource = 'Bilinmiyor';
  List<double> _frequencies = const [];
  List<String> _onlineCpus = const [];
  Map<String, double> _thermal = const {};
  Map<String, dynamic> _device = const {};
  int _previousTotal = 0;
  int _previousIdle = 0;

  bool get _glass => widget.selectedStyle != AppThemeStyle.normal;
  bool get _light => widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final cpu = await _readCpu();
      final ram = await _readRam();
      final native = await _readNative();
      if (!mounted) return;
      setState(() {
        _cpu = cpu;
        _ramTotal = ram.$1;
        _ramAvailable = ram.$2;
        _ramUsed = ram.$1 > 0 ? (ram.$1 - ram.$2).clamp(0, ram.$1).toDouble() : 0;
        _applyNative(native);
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<double> _readCpu() async {
    try {
      final lines = await File('/proc/stat').readAsLines();
      final line = lines.cast<String?>().firstWhere((e) => e?.startsWith('cpu ') == true, orElse: () => null);
      if (line == null) return _cpu;
      final values = line.trim().split(RegExp(r'\s+')).skip(1).take(8).map(int.tryParse).whereType<int>().toList();
      if (values.length < 4) return _cpu;
      final idle = values[3] + (values.length > 4 ? values[4] : 0);
      final total = values.fold<int>(0, (a, b) => a + b);
      if (_previousTotal == 0) {
        _previousTotal = total;
        _previousIdle = idle;
        return _cpu;
      }
      final totalDelta = total - _previousTotal;
      final idleDelta = idle - _previousIdle;
      _previousTotal = total;
      _previousIdle = idle;
      if (totalDelta <= 0) return _cpu;
      return ((1 - idleDelta / totalDelta) * 100).clamp(0, 100).toDouble();
    } catch (_) {
      return _cpu;
    }
  }

  Future<(double, double)> _readRam() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      int? total;
      int? available;
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) total = int.tryParse(RegExp(r'\d+').firstMatch(line)?.group(0) ?? '');
        if (line.startsWith('MemAvailable:')) available = int.tryParse(RegExp(r'\d+').firstMatch(line)?.group(0) ?? '');
      }
      if (total == null || available == null) return (_ramTotal, _ramAvailable);
      return (total / 1048576, available / 1048576);
    } catch (_) {
      return (_ramTotal, _ramAvailable);
    }
  }

  Future<Map<String, dynamic>> _readNative() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSystemMonitorDetails');
      if (result != null) return result.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return const {};
  }

  void _applyNative(Map<String, dynamic> data) {
    final frequencies = <double>[];
    final rawFrequencies = data['cpu_frequencies'];
    if (rawFrequencies is List) {
      for (final value in rawFrequencies) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null && parsed > 0) frequencies.add(parsed);
      }
    }

    final online = <String>[];
    final rawOnline = data['online_cpus'];
    if (rawOnline is List) {
      online.addAll(rawOnline.map((e) => e.toString()));
    } else if (rawOnline != null) {
      online.addAll(rawOnline.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    final thermal = <String, double>{};
    final rawThermal = data['thermal_zones'];
    if (rawThermal is Map) {
      rawThermal.forEach((key, value) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null && parsed >= -40 && parsed <= 150) thermal[key.toString()] = parsed;
      });
    }

    var battery = _battery;
    final rawBattery = data['battery_level'];
    if (rawBattery is num) battery = rawBattery.toInt();
    var temp = _batteryTemp;
    final rawTemp = data['battery_temperature'];
    if (rawTemp is num && rawTemp >= 0) temp = rawTemp.toDouble();

    _frequencies = frequencies;
    _onlineCpus = online;
    _thermal = thermal;
    _battery = battery;
    _batteryTemp = temp;
    _batteryState = data['battery_state']?.toString() ?? _batteryState;
    _batterySource = data['battery_source']?.toString() ?? _batterySource;
    _device = _device;
  }

  Future<void> _loadBatteryFallback() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryStatus');
      if (result == null || !mounted) return;
      setState(() {
        final level = result['level'];
        if (level is num) _battery = level.toInt();
        final temp = result['temperature'];
        if (temp is num && temp >= 0) _batteryTemp = temp.toDouble();
        _batteryState = result['state']?.toString() ?? _batteryState;
        _batterySource = result['source']?.toString() ?? _batterySource;
      });
    } catch (_) {}
  }

  Future<void> _loadDevice() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      if (result != null && mounted) setState(() => _device = result.map((k, v) => MapEntry(k.toString(), v)));
    } catch (_) {}
  }

  String _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? 'Bilinmiyor' : text;
  }

  String _freq(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)} GHz';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)} MHz';
    return '${value.toStringAsFixed(0)} kHz';
  }

  Widget _card(Widget child) {
    final scheme = Theme.of(context).colorScheme;
    if (!_glass) return Card(child: child);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_light ? .18 : .065),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(_light ? .50 : .16)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon) => _card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 13),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final ramPercent = _ramTotal <= 0 ? 0 : (_ramUsed / _ramTotal * 100).clamp(0, 100);
    final deviceModel = _text(_device['model']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor'),
        centerTitle: true,
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDevice();
          await _loadBatteryFallback();
          await _refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _card(Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(deviceModel, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_text(_device['manufacturer'])} • Android ${_text(_device['release'])} • SDK ${_text(_device['sdk_int'])}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                Text('CPU ${_cpu.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                LinearProgressIndicator(value: _cpu / 100, minHeight: 7, borderRadius: BorderRadius.circular(8)),
              ]),
            )),
            const SizedBox(height: 10),
            _metric('RAM', '${_ramUsed.toStringAsFixed(1)} / ${_ramTotal.toStringAsFixed(1)} GB (${ramPercent.toStringAsFixed(0)}%)', Icons.memory_outlined),
            const SizedBox(height: 8),
            _metric('Batarya', _battery >= 0 ? '$_battery% • $_batteryState' : 'Bilinmiyor', Icons.battery_full_outlined),
            const SizedBox(height: 8),
            _metric('Batarya sıcaklığı', _batteryTemp == null ? 'Bilinmiyor' : '${_batteryTemp!.toStringAsFixed(1)} °C', Icons.thermostat_outlined),
            const SizedBox(height: 14),
            Text('İşlemci', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 7),
            _card(Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_onlineCpus.isEmpty ? 'Çevrimiçi CPU bilgisi yok' : '${_onlineCpus.length} CPU çevrimiçi'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (_frequencies.isEmpty) const Text('Frekans bilgisi erişilemiyor.') else ..._frequencies.take(16).toList().asMap().entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('CPU ${entry.key}: ${_freq(entry.value)}'))),
              ]),
            )),
            const SizedBox(height: 14),
            Text('Termal sensörler', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 7),
            _card(Padding(
              padding: const EdgeInsets.all(16),
              child: _thermal.isEmpty
                  ? const Text('Termal sensör bilgisi bu cihaz/ROM tarafından erişilebilir olarak sunulmuyor.')
                  : Column(children: _thermal.entries.take(20).map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.device_thermostat_outlined), title: Text(e.key), trailing: Text('${e.value.toStringAsFixed(1)} °C', style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
            )),
            const SizedBox(height: 14),
            Text('Sistem bilgileri', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 7),
            _card(Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _infoRow('Model', deviceModel),
                _infoRow('Marka', _text(_device['brand'])),
                _infoRow('SoC', _text(_device['soc_model'])),
                _infoRow('ABI', _text(_device['supported_abis'])),
                _infoRow('CPU çekirdek', _text(_device['cpu_count'])),
                _infoRow('Ekran', '${_text(_device['screen_width'])} × ${_text(_device['screen_height'])}'),
                _infoRow('Yenileme', '${_text(_device['refresh_rate'])} Hz'),
                _infoRow('Güvenlik yaması', _text(_device['security_patch'])),
                _infoRow('Batarya kaynağı', _batterySource),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(title)), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w650)))]),
      );
}
