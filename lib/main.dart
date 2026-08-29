import 'dart:async';
import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
        ),
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
    "[    0.000000] ThisLinux kernel 1.1.0 starting...",
    "[    0.002341] BIOS: probing system firmware",
    "[    0.004782] BIOS: firmware interfaces detected",
    "[    0.007123] Kernel: early initialization",
    "[    0.009464] Kernel: initializing CPU subsystem",
    "[    0.011805] CPU: processor architecture detected",
    "[    0.014146] CPU0: booting processor",
    "[    0.016487] CPU1: online",
    "[    0.018828] CPU2: online",
    "[    0.021169] CPU3: online",
    "[    0.023510] SMP: multiprocessor initialization complete",
    "[    0.025851] Memory: initializing memory manager",
    "[    0.028192] Memory: physical memory detected",
    "[    0.030533] Memory: virtual memory enabled",
    "[    0.032874] Kernel: initializing scheduler",
    "[    0.035215] Kernel: scheduler initialized",
    "[    0.037556] Timer: high resolution timers enabled",
    "[    0.039897] ACPI: initializing system",
    "[    0.042238] ACPI: hardware interfaces detected",
    "[    0.044579] PCI: probing hardware buses",
    "[    0.046920] PCI: bus 0000 initialized",
    "[    0.049261] PCI: device enumeration complete",
    "[    0.051602] USB: initializing USB subsystem",
    "[    0.053943] USB: host controller detected",
    "[    0.056284] USB: enumerating devices",
    "[    0.058625] USB: USB subsystem ready",
    "[    0.060966] Storage: detecting block devices",
    "[    0.063307] Storage: block device subsystem initialized",
    "[    0.065648] Storage: scanning partitions",
    "[    0.067989] Storage: partition scan complete",
    "[    0.070330] VFS: virtual filesystem initialized",
    "[    0.072671] VFS: mounting root filesystem",
    "[    0.075012] VFS: root filesystem mounted",
    "[    0.077353] EXT4: filesystem driver loaded",
    "[    0.079694] EXT4: root filesystem online",
    "[    0.082035] Display: initializing graphics subsystem",
    "[    0.084376] DRM: direct rendering manager initialized",
    "[    0.086717] GPU: detecting graphics processor",
    "[    0.089058] GPU: graphics processor detected",
    "[    0.091399] GPU: loading graphics driver",
    "[    0.093740] GPU: graphics driver initialized",
    "[    0.096081] GPU: hardware acceleration enabled",
    "[    0.098422] Audio: initializing audio subsystem",
    "[    0.100763] Audio: sound device detected",
    "[    0.103104] Audio: audio driver initialized",
    "[    0.105445] Network: initializing network stack",
    "[    0.107786] Network: loading network protocols",
    "[    0.110127] Network: network interface detected",
    "[    0.112468] Network: wireless subsystem initialized",
    "[    0.114809] Network: network manager started",
    "[    0.117150] Bluetooth: initializing subsystem",
    "[    0.119491] Bluetooth: controller detected",
    "[    0.121832] Security: initializing security modules",
    "[    0.124173] Security: verifying system integrity",
    "[    0.126514] Security: integrity check passed",
    "[    0.128855] Drivers: loading hardware drivers",
    "[    0.131196] Drivers: USB driver loaded",
    "[    0.133537] Drivers: display driver loaded",
    "[    0.135878] Drivers: audio driver loaded",
    "[    0.138219] Drivers: network driver loaded",
    "[    0.140560] Drivers: storage driver loaded",
    "[    0.142901] Drivers: hardware initialization complete",
    "[    0.145242] Modules: loading kernel modules",
    "[    0.147583] Modules: core modules loaded",
    "[    0.149924] Modules: device modules loaded",
    "[    0.152265] Runtime: initializing runtime",
    "[    0.154606] Runtime: loading system libraries",
    "[    0.156947] Runtime: loading application framework",
    "[    0.159288] Runtime: initializing Flutter engine",
    "[    0.161629] Runtime: rendering engine initialized",
    "[    0.163970] Services: starting system services",
    "[    0.166311] Services: network service started",
    "[    0.168652] Services: storage service started",
    "[    0.170993] Services: display service started",
    "[    0.173334] Services: power service started",
    "[    0.175675] Services: background services ready",
    "[    0.178016] System: checking filesystem",
    "[    0.180357] System: filesystem check complete",
    "[    0.182698] System: checking system integrity",
    "[    0.185039] System: integrity check passed",
    "[    0.187380] System: loading user environment",
    "[    0.189721] System: preparing graphical interface",
    "[    0.192062] UI: initializing user interface",
    "[    0.194403] UI: loading interface components",
    "[    0.196744] UI: preparing application environment",
    "[    0.199085] ThisLinux: initializing application",
    "[    0.201426] ThisLinux: loading device information",
    "[    0.203767] ThisLinux: loading system information",
    "[    0.206108] ThisLinux: loading battery service",
    "[    0.208449] ThisLinux: loading performance service",
    "[    0.210790] ThisLinux: initializing dashboard",
    "[    0.213131] ThisLinux: preparing interface",
    "[    0.215472] ThisLinux: starting user interface",
    "[    0.217813] System: finalizing startup sequence",
    "[    0.220154] System: all services operational",
    "[    0.222495] Boot: performing final checks",
    "[    0.224836] Boot: final checks passed",
    "[    0.227177] Boot: initialization complete",
    "[    0.229518] Boot: starting ThisLinux",
    "[    0.231859] Welcome to ThisLinux.",
  ];

  final List<String> visibleLines = [];

  Timer? _bootTimer;
  int currentLine = 0;

  @override
  void initState() {
    super.initState();

    _bootTimer = Timer.periodic(
      const Duration(milliseconds: 40),
      (_) => _addNextLine(),
    );
  }

  void _addNextLine() {
    if (!mounted) return;

    if (currentLine >= bootLines.length) {
      _bootTimer?.cancel();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 300),
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
                height: 1.05,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();

  String _model = "Loading...";
  String _manufacturer = "Loading...";
  String _androidVersion = "Loading...";
  String _sdk = "Loading...";
  String _batteryLevel = "Loading...";
  String _batteryState = "Loading...";
  String _appVersion = "1.1.0";

  bool _updateAvailable = false;
  String _latestVersion = "";
  String _updateUrl = "";

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
    _checkForUpdate();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final info = await _deviceInfo.androidInfo;
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      final packageInfo = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _model = info.model;
        _manufacturer = info.manufacturer;
        _androidVersion = info.version.release;
        _sdk = info.version.sdkInt.toString();
        _batteryLevel = "$batteryLevel%";
        _batteryState = _batteryStateText(batteryState);
        _appVersion = packageInfo.version;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _model = "Unknown";
        _manufacturer = "Unknown";
        _androidVersion = "Unknown";
        _sdk = "Unknown";
        _batteryLevel = "Unknown";
        _batteryState = "Unknown";
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

  Future<void> _checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/TechyTR/ThisLinux-app/main/version.json',
        ),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final latest = data['latest_version']?.toString() ?? "";
      final url = data['download_url']?.toString() ?? "";

      if (latest.isEmpty) return;

      final current = await PackageInfo.fromPlatform();

      if (_isNewerVersion(latest, current.version) && mounted) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = latest;
          _updateUrl = url;
        });
      }
    } catch (_) {
      // İnternet bağlantısı yoksa uygulama normal çalışır.
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final latestNumber =
          i < latestParts.length ? (latestParts[i] ?? 0) : 0;

      final currentNumber =
          i < currentParts.length ? (currentParts[i] ?? 0) : 0;

      if (latestNumber > currentNumber) {
        return true;
      }

      if (latestNumber < currentNumber) {
        return false;
      }
    }

    return false;
  }

  Future<void> _openUpdate() async {
    if (_updateUrl.isEmpty) return;

    final uri = Uri.parse(_updateUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SYSTEM INFORMATION",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _infoRow("Manufacturer", _manufacturer),
                _infoRow("Model", _model),
                _infoRow("Android", _androidVersion),
                _infoRow("SDK", _sdk),
                _infoRow("Battery", _batteryLevel),
                _infoRow("Power", _batteryState),
                const SizedBox(height: 25),
                const Text(
                  "SYSTEM STATUS",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "[ OK ] ThisLinux system operational",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
                const Text(
                  "[ OK ] All services running",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 14,
            bottom: 12,
            child: Text(
              "v$_appVersion",
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),

          if (_updateAvailable)
            Positioned(
              left: 14,
              right: 14,
              bottom: 45,
              child: OutlinedButton(
                onPressed: _openUpdate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                ),
                child: Text(
                  "UPDATE AVAILABLE  →  v$_latestVersion",
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

