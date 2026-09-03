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
  bool _loading = true;

  bool get _isGlass =>
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle ==
      AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getShizukuStatus',
      );

      if (result != null && mounted) {
        setState(() {
          _installed =
              result['installed'] == true;
          _running =
              result['running'] == true;
          _permissionGranted =
              result['permissionGranted'] == true;
          _suAvailable =
              result['suAvailable'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _installed = false;
          _running = false;
          _permissionGranted = false;
          _suAvailable = false;
        });
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openShizuku() async {
    try {
      await _channel.invokeMethod('openShizuku');
    } catch (_) {}
  }

  Future<void> _connect() async {
    try {
      await _channel.invokeMethod('connectShizuku');
    } catch (_) {}

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    await _loadStatus();
  }

  Widget _card(Widget child) {
    final scheme = Theme.of(context).colorScheme;

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: _isGlass
            ? Colors.white.withOpacity(
                _isLightGlass ? 0.15 : 0.065,
              )
            : scheme.surfaceContainerHighest,
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.50 : 0.18,
                ),
              )
            : null,
      ),
      child: child,
    );

    if (_isGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _statusRow(
    String title,
    bool value,
  ) {
    final color = value
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        title: const Text('Shizuku'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loadStatus,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              children: [
                _card(
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: scheme.primary
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 31,
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
                                  'Shizuku bağlantısı',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Stellar Center sistem erişimi',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  Column(
                    children: [
                      _statusRow(
                        'Shizuku yüklü',
                        _installed,
                      ),
                      _statusRow(
                        'Shizuku çalışıyor',
                        _running,
                      ),
                      _statusRow(
                        'Stellar Center yetkili',
                        _permissionGranted,
                      ),
                      _statusRow(
                        'SU yetkisi var',
                        _suAvailable,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_installed)
                  _card(
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shizuku yüklenmemiş',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stellar Center ile gelişmiş sistem erişimi kullanmak için önce Shizuku kurulmalıdır.',
                          style: TextStyle(
                            color:
                                scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _openShizuku,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                            ),
                            label: const Text(
                              'Shizuku yükle',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_running)
                  _card(
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shizuku çalışmıyor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Önce Shizuku uygulamasını başlatın.',
                          style: TextStyle(
                            color:
                                scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _openShizuku,
                            child: const Text(
                              'Shizuku\'yu aç',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_permissionGranted)
                  _card(
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stellar Center yetkisi gerekiyor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Shizuku çalışıyor. Şimdi Stellar Center için Shizuku izni verin.',
                          style: TextStyle(
                            color:
                                scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _connect,
                            icon: const Icon(
                              Icons.link_rounded,
                            ),
                            label: const Text(
                              'Shizuku\'yu bağla',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _card(
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bağlantı hazır',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _suAvailable
                              ? 'Shizuku bağlantısı aktif ve SU seviyesi erişilebilir.'
                              : 'Shizuku bağlantısı aktif. Root/SU yetkisi bulunmuyor.',
                          style: TextStyle(
                            color:
                                scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Shizuku root değildir. Android sistem API\'lerine daha gelişmiş erişim sağlar. Root erişimi varsa ayrıca algılanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}
