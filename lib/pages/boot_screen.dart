import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
    '[  OK  ] Starting ThisLinux...',
    '[  OK  ] Initializing system...',
    '[  OK  ] Loading system information...',
    '[  OK  ] Starting system services...',
    '[  OK  ] Checking device...',
    '[  OK  ] ThisLinux is ready.',
  ];

  final List<String> _visibleLines = [];

  Timer? _timer;

  bool _showLogo = false;
  bool _finished = false;

  int _currentLine = 0;

  @override
  void initState() {
    super.initState();
    _startBootAnimation();
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
      backgroundColor:
          Colors.black,
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
                      'ThisLinux',
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
                  'assets/linux_logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons.computer,
                      color: Colors.white,
                      size: 90,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
