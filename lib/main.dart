import 'dart:async';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

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
    "[    0.091399] GPU: Graphics driver initialized",
    "[    0.093740] GPU: Hardware acceleration enabled",
    "[    0.096081] Audio: Initializing audio subsystem",
    "[    0.098422] Audio: Sound device detected",
    "[    0.100763] Network: Initializing network stack",
    "[    0.103104] Network: Loading network protocols",
    "[    0.105445] Network: Network interface detected",
    "[    0.107786] Bluetooth: Initializing subsystem",
    "[    0.110127] Security: Initializing security modules",
    "[    0.112468] Security: Verifying system integrity",
    "[    0.114809] Security: Integrity check passed",
    "[    0.117150] Drivers: Loading hardware drivers",
    "[    0.119491] Drivers: USB driver loaded",
    "[    0.121832] Drivers: Display driver loaded",
    "[    0.124173] Drivers: Audio driver loaded",
    "[    0.126514] Drivers: Network driver loaded",
    "[    0.128855] Drivers: Storage driver loaded",
    "[    0.131196] Drivers: Hardware initialization complete",
    "[    0.133537] Modules: Loading kernel modules",
    "[    0.135878] Modules: Core modules loaded",
    "[    0.138219] Modules: Device modules loaded",
    "[    0.140560] Modules: System modules loaded",
    "[    0.142901] Runtime: Initializing runtime",
    "[    0.145242] Runtime: Loading system libraries",
    "[    0.147583] Runtime: Loading application framework",
    "[    0.149924] Runtime: Initializing Flutter engine",
    "[    0.152265] Runtime: Rendering engine initialized",
    "[    0.154606] Runtime: Graphics pipeline ready",
    "[    0.156947] Services: Starting system services",
    "[    0.159288] Services: Network service started",
    "[    0.161629] Services: Storage service started",
    "[    0.163970] Services: Display service started",
    "[    0.166311] Services: Audio service started",
    "[    0.168652] Services: Power service started",
    "[    0.170993] Services: Background services ready",
    "[    0.173334] System: Checking filesystem",
    "[    0.175675] System: Filesystem check complete",
    "[    0.178016] System: Checking system integrity",
    "[    0.180357] System: Integrity check passed",
    "[    0.182698] System: Loading user environment",
    "[    0.185039] System: Preparing graphical interface",
    "[    0.187380] UI: Initializing user interface",
    "[    0.189721] UI: Loading interface components",
    "[    0.192062] UI: Loading system widgets",
    "[    0.194403] UI: Preparing application environment",
    "[    0.196744] ThisLinux: Initializing application",
    "[    0.199085] ThisLinux: Loading device information",
    "[    0.201426] ThisLinux: Loading battery service",
    "[    0.203767] ThisLinux: Loading system monitor",
    "[    0.206108] ThisLinux: Loading performance service",
    "[    0.208449] ThisLinux: Initializing dashboard",
    "[    0.210790] ThisLinux: Preparing interface",
    "[    0.213131] ThisLinux: Starting user interface",
    "[    0.215472] System: Finalizing startup sequence",
    "[    0.217813] System: Starting background tasks",
    "[    0.220154] System: All services operational",
    "[    0.222495] Boot: Performing final checks",
    "[    0.224836] Boot: Final checks passed",
    "[    0.227177] Boot: System initialization complete",
    "[    0.229518] Boot: Starting ThisLinux",
    "[    0.231859] Boot: Application ready",
    "[    0.234200] Welcome to ThisLinux",
  ];

  final List<String> visibleLines = [];

  Timer? _bootTimer;
  int currentLine = 0;

  @override
  void initState() {
    super.initState();

    _bootTimer = Timer.periodic(
      const Duration(milliseconds: 38),
      (_) => _addNextLine(),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// SYSTEM INFORMATION
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();

  String deviceName = "Loading...";
  String manufacturer = "Loading...";
  String model = "Loading...";
  String androidVersion = "Loading...";
  String sdkVersion = "Loading...";
  String batteryLevel = "Loading...";
  String batteryStatus = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      if (!mounted) return;

      setState(() {
        deviceName = androidInfo.device;
        manufacturer = androidInfo.manufacturer;
        model = androidInfo.model;
        androidVersion = androidInfo.version.release;
        sdkVersion = androidInfo.version.sdkInt.toString();
        batteryLevel = "$level%";
        batteryStatus = _batteryStateText(state);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deviceName = "Unknown";
        manufacturer = "Unknown";
        model = "Unknown";
        androidVersion = "Unknown";
        sdkVersion = "Unknown";
        batteryLevel = "Unknown";
        batteryStatus = "Unknown";
      });
    }
  }

  String _batteryStateText(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return "Charging";
      case BatteryState.full:
        return "Full";
      case BatteryState.discharging:
        return "Discharging";
      case BatteryState.connectedNotCharging:
        return "Connected";
      case BatteryState.unknown:
        return "Unknown";
    }
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "This Linux",
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSystemInfo,
        color: Colors.white,
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "SYSTEM INFORMATION",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 8),

            const Divider(color: Colors.white24),

            const SizedBox(height: 8),

            _infoRow("Device", deviceName),
            _infoRow("Manufacturer", manufacturer),
            _infoRow("Model", model),
            _infoRow("Android", androidVersion),
            _infoRow("SDK", sdkVersion),

            const SizedBox(height: 12),

            const Text(
              "BATTERY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 8),

            const Divider(color: Colors.white24),

            const SizedBox(height: 8),

            _infoRow("Level", batteryLevel),
            _infoRow("Status", batteryStatus),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                "ThisLinux System Monitor",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

