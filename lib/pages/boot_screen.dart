import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/update_button.dart';
import 'home_shell.dart';

class BootScreen extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(
    AppThemeColor,
  ) onThemeChanged;

  final Future<void> Function(
    AppThemeStyle,
  ) onStyleChanged;

  const BootScreen({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<BootScreen> createState() =>
      _BootScreenState();
}

class _BootScreenState
    extends State<BootScreen> {
  final List<String> _bootLines = [
    '[  OK  ] Starting Stellar Center...',
    '[  OK  ] Initializing system...',
    '[  OK  ] Loading system information...',
    '[  OK  ] Starting system services...',
    '[  OK  ] Checking device...',
    '[  OK  ] Stellar Center is ready.',
  ];

  final List<String> _visibleLines = [];

  Timer? _timer;

  bool _showLogo = false;
  bool _finished = false;
  bool _updateAvailable = false;

  String _currentVersion =
      'Yükleniyor...';

  int _currentLine = 0;

  @override
  void initState() {
    super.initState();

    _loadVersion();
    _startBootAnimation();
    _checkUpdate();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _currentVersion =
            packageInfo.version;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentVersion =
            'Bilinmiyor';
      });
    }
  }

  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      return packageInfo.version;
    } catch (_) {
      return '0.0';
    }
  }

  Future<void> _checkUpdate() async {
    final update =
        await UpdateService.checkForUpdate();

    if (!mounted || update == null) {
      return;
    }

    final currentVersion =
        await _getCurrentVersion();

    if (!mounted) return;

    setState(() {
      _currentVersion =
          currentVersion;

      _updateAvailable =
          UpdateService.isNewerVersion(
        currentVersion,
        update.latestVersion,
      );
    });
  }

  void _startBootAnimation() {
    const totalBootTime =
        Duration(seconds: 2);

    final lineDuration =
        totalBootTime.inMilliseconds ~/
            _bootLines.length;

    _timer = Timer.periodic(
      Duration(
        milliseconds: lineDuration,
      ),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_currentLine <
            _bootLines.length) {
          setState(() {
            _visibleLines.add(
              _bootLines[_currentLine],
            );

            _currentLine++;
          });
        }

        if (_currentLine >=
            _bootLines.length) {
          timer.cancel();
          _showLinuxLogo();
        }
      },
    );
  }

  Future<void> _showLinuxLogo() async {
    if (!mounted) return;

    setState(() {
      _showLogo = true;
    });

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) return;

    setState(() {
      _finished = true;
    });
  }

  void _showUpdateDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Yeni sürüm bulundu',
          ),
          content: Text(
            'Stellar Center için yeni '
            'bir sürüm mevcut.\n\n'
            'Mevcut sürüm: '
            'v$_currentVersion\n\n'
            'Güncelleme ekranını açmak '
            'ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Daha sonra',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: const Text(
                          'Güncelleme',
                        ),
                      ),
                      body: ListView(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        children: [
                          UpdateButton(
                            currentVersion:
                                _currentVersion,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                'Aç',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_finished) {
      return HomeShell(
        selectedTheme:
            widget.selectedTheme,
        selectedStyle:
            widget.selectedStyle,
        onThemeChanged:
            widget.onThemeChanged,
        onStyleChanged:
            widget.onStyleChanged,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (!_showLogo)
              Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stellar Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    ..._visibleLines.map(
                      (line) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 5,
                        ),
                        child: Text(
                          line,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontFamily:
                                'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showLogo)
              Center(
                child: Image.asset(
                  'assets/icon.png',
                  width: 110,
                  height: 110,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons
                          .auto_awesome_rounded,
                      color: Colors.white,
                      size: 90,
                    );
                  },
                ),
              ),
            if (_updateAvailable)
              Positioned(
                right: 18,
                bottom: 18,
                child: FilledButton.icon(
                  onPressed:
                      _showUpdateDialog,
                  icon: const Icon(
                    Icons.system_update,
                  ),
                  label: const Text(
                    'UPDATE',
                  ),
                ),
              ),
            Positioned(
              right: 18,
              bottom: 4,
              child: Text(
                'v$_currentVersion',
                style:
                    const TextStyle(
                  color: Colors.white54,
                  fontFamily:
                      'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
