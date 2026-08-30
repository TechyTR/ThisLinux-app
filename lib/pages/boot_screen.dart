import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_shell.dart';

class BootScreen extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Future<void> Function(AppThemeColor) onThemeChanged;

  const BootScreen({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final ScrollController scrollController = ScrollController();

  Timer? bootTimer;

  final List<String> shown = [];

  int index = 0;

  final List<String> bootMessages = [
    'Booting ThisLinux kernel...',
    'Initializing kernel subsystems',
    'Initializing memory management',
    'Initializing virtual memory',
    'Initializing scheduler',
    'Initializing process management',
    'Initializing interrupt controller',
    'Initializing system timers',
    'Initializing kernel workqueues',
    'Initializing RCU subsystem',
    'Initializing task scheduler',
    'Initializing CPU frequency management',
    'Initializing power management',
    'Initializing thermal management',
    'Initializing device tree',
    'Parsing hardware configuration',
    'Detecting processor architecture',
    'Detecting CPU cores',
    'Detecting available memory',
    'Detecting memory regions',
    'Setting up DMA subsystem',
    'Initializing IOMMU',
    'Initializing cache subsystem',
    'Initializing filesystem layer',
    'Initializing block devices',
    'Initializing character devices',
    'Initializing virtual filesystem',
    'Mounting virtual filesystems',
    'Initializing security framework',
    'Initializing SELinux',
    'Loading security policies',
    'Initializing cryptographic subsystem',
    'Initializing random number generator',
    'Initializing kernel logging',
    'Initializing networking stack',
    'Initializing socket layer',
    'Initializing TCP/IP stack',
    'Initializing UDP subsystem',
    'Initializing IPv6 subsystem',
    'Initializing network interfaces',
    'Initializing USB subsystem',
    'Initializing HID subsystem',
    'Initializing input devices',
    'Initializing display subsystem',
    'Initializing framebuffer',
    'Initializing GPU subsystem',
    'Loading GPU firmware',
    'Initializing audio subsystem',
    'Loading audio drivers',
    'Initializing Bluetooth subsystem',
    'Loading Bluetooth firmware',
    'Initializing Wi-Fi subsystem',
    'Loading Wi-Fi firmware',
    'Initializing sensor framework',
    'Detecting accelerometer',
    'Detecting gyroscope',
    'Detecting proximity sensor',
    'Detecting light sensor',
    'Initializing camera subsystem',
    'Initializing battery management',
    'Reading battery information',
    'Initializing charger interface',
    'Initializing storage controller',
    'Detecting internal storage',
    'Checking partition table',
    'Mounting system partition',
    'Mounting vendor partition',
    'Mounting product partition',
    'Mounting data partition',
    'Checking filesystem integrity',
    'Initializing package manager',
    'Loading system libraries',
    'Loading runtime environment',
    'Starting Android runtime',
    'Starting Zygote process',
    'Starting system server',
    'Starting activity manager',
    'Starting package manager service',
    'Starting window manager',
    'Starting power manager',
    'Starting connectivity service',
    'Starting notification service',
    'Starting sensor service',
    'Starting audio service',
    'Starting Bluetooth service',
    'Starting Wi-Fi service',
    'Starting display service',
    'Starting input service',
    'Starting storage service',
    'Starting media service',
    'Starting graphics service',
    'Starting application manager',
    'Loading system configuration',
    'Loading device configuration',
    'Loading user preferences',
    'Preparing application environment',
    'Initializing ThisLinux services',
    'Loading ThisLinux interface',
    'Preparing system information',
    'Preparing application information',
    'Preparing local storage',
    'Checking application resources',
    'Checking application configuration',
    'Initializing theme system',
    'Initializing navigation system',
    'Starting user interface',
    'Finalizing system initialization',
    'Cleaning temporary resources',
    'Synchronizing system state',
    'System services initialized',
    'System initialization complete',
    'Starting ThisLinux',
  ];

  late final List<String> bootLines;

  @override
  void initState() {
    super.initState();

    bootLines = _generateBootLines();

    bootTimer = Timer.periodic(
      const Duration(milliseconds: 10),
      _showNextLine,
    );
  }

  List<String> _generateBootLines() {
    final List<String> lines = [];

    for (int i = 0; i < 300; i++) {
      final message = bootMessages[i % bootMessages.length];

      final seconds = i * 0.01;

      lines.add(
        '[${seconds.toStringAsFixed(6).padLeft(9, ' ')}] $message',
      );
    }

    return lines;
  }

  void _showNextLine(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (index < bootLines.length) {
      setState(() {
        shown.add(bootLines[index]);
        index++;
      });

      if (scrollController.hasClients) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }

      return;
    }

    timer.cancel();

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeShell(
              selectedTheme: widget.selectedTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    bootTimer?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          controller: scrollController,
          itemCount: shown.length,
          itemBuilder: (context, index) {
            return Text(
              shown[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            );
          },
        ),
      ),
    );
  }
}
