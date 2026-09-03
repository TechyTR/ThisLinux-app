import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ShizukuPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  const ShizukuPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
  });

  @override
  State<ShizukuPage> createState() => _ShizukuPageState();
}

class _ShizukuPageState extends State<ShizukuPage> {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  bool _installed = false;
  bool _running = false;
  bool _permissionGranted = false;
  bool _suAvailable = false;

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getShizukuStatus',
      );

      if (!mounted || result == null) return;

      setState(() {
        _installed = result['installed'] == true;
        _running = result['running'] == true;
        _permissionGranted =
            result['permission_granted'] == true;
        _suAvailable = result['su_available'] == true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _installed = false;
        _running = false;
        _permissionGranted = false;
        _suAvailable = false;
      });
    }
  }

  Future<void> _connect() async {
    try {
      await _channel.invokeMethod(
        'connectShizuku',
      );
    } catch (_) {}

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    await _checkStatus();
  }

  Future<void> _openShizuku() async {
    try {
      await _channel.invokeMethod(
        'openShizuku',
      );
    } catch (_) {}
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 24,
  }) {
    if (!_isGlass) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25,
          sigmaY: 25,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(
              _isLightGlass ? 0.17 : 0.07,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                _isLightGlass ? 0.60 : 0.21,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isLightGlass ? 0.06 : 0.18,
                ),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: padding,
                child: child,
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 0,
                height: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(
                            _isLightGlass ? 0.80 : 0.38,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow({
    required String title,
    required bool active,
    required IconData icon,
  }) {
    final color = active
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              active
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            icon,
            color: color,
            size: 23,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shizuku bağlantısı',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _checkStatus,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          children: [
            _glassCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(
                        _isGlass ? 0.10 : 0.13,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.cable_rounded,
                      size: 32,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shizuku',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gelişmiş Android sistem erişimi',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_installed)
              _glassCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shizuku yüklü değil',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Gelişmiş bağlantıyı kullanmak için Shizuku kurulmalıdır.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _openShizuku,
                        child: const Text(
                          'Shizuku yükle',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _statusRow(
              title: 'Shizuku çalışıyor',
              active: _running,
              icon: Icons.power_rounded,
            ),
            const SizedBox(height: 10),
            _statusRow(
              title: 'Stellar Center yetkili',
              active: _permissionGranted,
              icon: Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 10),
            _statusRow(
              title: 'SU yetkisi var',
              active: _suAvailable,
              icon: Icons.terminal_rounded,
            ),
            const SizedBox(height: 16),
            if (_installed && !_running)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _openShizuku,
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                  ),
                  label: const Text(
                    'Shizuku’yu bağla',
                  ),
                ),
              ),
            if (_installed && _running && !_permissionGranted)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(
                    Icons.security_rounded,
                  ),
                  label: const Text(
                    'Stellar Center’a izin ver',
                  ),
                ),
              ),
            const SizedBox(height: 18),
            _glassCard(
              child: Text(
                'Shizuku, Stellar Secure için daha gelişmiş Android API erişimi sağlayabilir. Root yetkisiyle aynı şey değildir ve Stellar Center güvenlik kontrollerini devre dışı bırakmaz.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
