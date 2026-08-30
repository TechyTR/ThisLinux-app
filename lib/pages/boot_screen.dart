import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_shell.dart';

class BootScreen extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;
  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const BootScreen({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final List<String> _logs = [
    '[  OK  ] Initializing ThisLinux',
    '[  OK  ] Loading system services',
    '[  OK  ] Checking device information',
    '[  OK  ] Loading user interface',
    '[  OK  ] Starting ThisLinux',
  ];

  int _visibleLogs = 0;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();
    _startBoot();
  }

  Future<void> _startBoot() async {
    for (int i = 0; i < _logs.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) return;

      setState(() {
        _visibleLogs = i + 1;
      });
    }

    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (!mounted) return;

    setState(() {
      _showLogo = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          return HomeShell(
            selectedTheme: widget.selectedTheme,
            selectedStyle: widget.selectedStyle,
            onThemeChanged: widget.onThemeChanged,
            onStyleChanged: widget.onStyleChanged,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showLogo
              ? Icon(
                  Icons.computer,
                  key: const ValueKey('logo'),
                  size: 72,
                  color: scheme.primary,
                )
              : Padding(
                  key: const ValueKey('logs'),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0;
                          i < _visibleLogs;
                          i++)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: Text(
                            _logs[i],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
