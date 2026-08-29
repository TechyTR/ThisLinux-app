import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const ThisLinuxApp());
}

class ThisLinuxApp extends StatelessWidget {
  const ThisLinuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'This Linux',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'monospace',
      ),
      home: const BootScreen(),
    );
  }
}

// ============================================================
// BOOT SCREEN
// ============================================================

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<String> bootLines = [
    "[    0.000000] Linux version 6.1.0-thislinux",
    "[    0.002341] Command line: console=tty0",
    "[    0.004782] BIOS-provided physical RAM map",
    "[    0.007123] Kernel: Early initialization",
    "[    0.009464] Kernel: Initializing CPU subsystem",
    "[    0.011805] CPU: Processor detected",
    "[    0.014146] CPU0: Booting processor",
    "[    0.016487] CPU1: Online",
    "[    0.018828] CPU2: Online",
    "[    0.021169] CPU3: Online",
    "[    0.023510] SMP: Multiprocessor initialization",
    "[    0.025851] Memory: Initializing memory manager",
    "[    0.028192] Memory: Physical memory detected",
    "[    0.030533] Memory: Virtual memory enabled",
    "[    0.032874] Kernel: Initializing scheduler",
    "[    0.035215] Kernel: Scheduler initialized",
    "[    0.037556] Kernel: Starting system timers",
    "[    0.039897] Timer: High resolution timers enabled",
    "[    0.042238] ACPI: Initializing system",
    "[    0.044579] ACPI: Hardware interfaces detected",
    "[    0.046920] PCI: Probing PCI hardware",
    "[    0.049261] PCI: Bus 0000 initialized",
    "[    0.051602] PCI: Device enumeration complete",
    "[    0.053943] USB: Initializing USB subsystem",
    "[    0.056284] USB: Host controller detected",
    "[    0.058625] USB: Device enumeration started",
    "[    0.060966] USB: USB subsystem ready",
    "[    0.063307] Storage: Detecting storage devices",
    "[    0.065648] Storage: Block device subsystem",
    "[    0.067989] Storage: Checking partitions",
    "[    0.070330] Storage: Partition scan complete",
    "[    0.072671] VFS: Virtual filesystem initialized",
    "[    0.075012] VFS: Mounting root filesystem",
    "[    0.077353] VFS: Root filesystem mounted",
    "[    0.079694] EXT4: Filesystem driver loaded",
    "[    0.082035] EXT4: Root filesystem online",
    "[    0.084376] Display: Initializing graphics subsystem",
    "[    0.086717] DRM: Direct rendering manager initialized",
    "[    0.089058] GPU: Detecting graphics processor",
    "[    0.091399] GPU: Graphics processor detected",
    "[    0.093740] GPU: Loading graphics driver",
    "[    0.096081] GPU: Graphics driver initialized",
    "[    0.098422] GPU: Hardware acceleration enabled",
    "[    0.100763] Audio: Initializing audio subsystem",
    "[    0.103104] Audio: Sound device detected",
    "[    0.105445] Audio: Audio driver initialized",
    "[    0.107786] Network: Initializing network stack",
    "[    0.110127] Network: Loading network protocols",
    "[    0.112468] Network: Network interface detected",
    "[    0.114809] Network: Wireless subsystem initialized",
    "[    0.117150] Network: Network manager started",
    "[    0.119491] Bluetooth: Initializing subsystem",
    "[    0.121832] Bluetooth: Controller detected",
    "[    0.124173] Security: Initializing security modules",
    "[    0.126514] Security: Verifying system integrity",
    "[    0.128855] Security: Integrity check passed",
    "[    0.131196] Drivers: Loading hardware drivers",
    "[    0.133537] Drivers: USB driver loaded",
    "[    0.135878] Drivers: Display driver loaded",
    "[    0.138219] Drivers: Audio driver loaded",
    "[    0.140560] Drivers: Network driver loaded",
    "[    0.142901] Drivers: Storage driver loaded",
    "[    0.145242] Drivers: Hardware initialization complete",
    "[    0.147583] Modules: Loading kernel modules",
    "[    0.149924] Modules: Core modules loaded",
    "[    0.152265] Modules: Device modules loaded",
    "[    0.154606] Modules: System modules loaded",
    "[    0.156947] Runtime: Initializing runtime",
    "[    0.159288] Runtime: Loading system libraries",
    "[    0.161629] Runtime: Loading application framework",
    "[    0.163970] Runtime: Initializing Flutter engine",
    "[    0.166311] Runtime: Rendering engine initialized",
    "[    0.168652] Runtime: Graphics pipeline ready",
    "[    0.170993] Services: Starting system services",
    "[    0.173334] Services: Network service started",
    "[    0.175675] Services: Storage service started",
    "[    0.178016] Services: Display service started",
    "[    0.180357] Services: Audio service started",
    "[    0.182698] Services: Power service started",
    "[    0.185039] Services: Background services ready",
    "[    0.187380] System: Checking filesystem",
    "[    0.189721] System: Filesystem check complete",
    "[    0.192062] System: Checking system integrity",
    "[    0.194403] System: Integrity check passed",
    "[    0.196744] System: Loading user environment",
    "[    0.199085] System: Preparing graphical interface",
    "[    0.201426] UI: Initializing user interface",
    "[    0.203767] UI: Loading interface components",
    "[    0.206108] UI: Loading system widgets",
    "[    0.208449] UI: Preparing application environment",
    "[    0.210790] ThisLinux: Initializing application",
    "[    0.213131] ThisLinux: Loading device information",
    "[    0.215472] ThisLinux: Loading system information",
    "[    0.217813] ThisLinux: Loading system monitor",
    "[    0.220154] ThisLinux: Loading hardware monitor",
    "[    0.222495] ThisLinux: Loading battery service",
    "[    0.224836] ThisLinux: Loading performance service",
    "[    0.227177] ThisLinux: Initializing dashboard",
    "[    0.229518] ThisLinux: Preparing interface",
    "[    0.231859] ThisLinux: Starting user interface",
    "[    0.234200] System: Finalizing startup sequence",
    "[    0.236541] System: Starting background tasks",
    "[    0.238882] System: All services operational",
    "[    0.241223] Boot: Performing final checks",
    "[    0.243564] Boot: Final checks passed",
    "[    0.245905] Boot: System initialization complete",
    "[    0.248246] Boot: Starting ThisLinux",
    "[    0.250587] Boot: Application ready",
    "[    0.252928] Welcome to ThisLinux",
  ];

  final List<String> visibleLines = [];

  Timer? _bootTimer;
  int currentLine = 0;

  @override
  void initState() {
    super.initState();

    // Yaklaşık 4 saniyede tamamlanır.
    _bootTimer = Timer.periodic(
      const Duration(milliseconds: 38),
      (_) {
        _addNextLine();
      },
    );
  }

  void _addNextLine() {
    if (!mounted) return;

    if (currentLine >= bootLines.length) {
      _bootTimer?.cancel();

      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      });

      return;
    }

    setState(() {
      visibleLines.add(bootLines[currentLine]);
      currentLine++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          physics: const ClampingScrollPhysics(),
          itemCount: visibleLines.length,
          itemBuilder: (context, index) {
            return Text(
              visibleLines[index],
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.08,
                letterSpacing: 0,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'This Linux',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'SYSTEM READY',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

