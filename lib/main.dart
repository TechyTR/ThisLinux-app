import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

enum AppThemeColor { purple, blue, green, orange }

extension AppThemeColorSeed on AppThemeColor {
  Color get seed {
    switch (this) {
      case AppThemeColor.purple:
        return const Color(0xFF8E7CC3);
      case AppThemeColor.blue:
        return const Color(0xFF5B8DEF);
      case AppThemeColor.green:
        return const Color(0xFF6FAE7A);
      case AppThemeColor.orange:
        return const Color(0xFFE0A972);
    }
  }

  String get label {
    switch (this) {
      case AppThemeColor.purple:
        return "Mor";
      case AppThemeColor.blue:
        return "Mavi";
      case AppThemeColor.green:
        return "Yeşil";
      case AppThemeColor.orange:
        return "Turuncu";
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeColor selectedTheme = AppThemeColor.purple;

  @override
  void initState() {
    super.initState();
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_color');
    if (saved != null) {
      setState(() {
        selectedTheme = AppThemeColor.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => AppThemeColor.purple,
        );
      });
    }
  }

  Future<void> changeTheme(AppThemeColor theme) async {
    setState(() {
      selectedTheme = theme;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color', theme.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'This Linux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: selectedTheme.seed,
          brightness: Brightness.dark,
        ),
      ),
      home: BootScreen(
        selectedTheme: selectedTheme,
        onThemeChanged: changeTheme,
      ),
    );
  }
}

class BootScreen extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Function(AppThemeColor) onThemeChanged;

  const BootScreen({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final List<String> bootLines = [
    "[    0.000000] Linux version 6.1.0-fake (gcc)",
    "[    0.012345] Kernel command line: root=/dev/fake ro",
    "[    0.034521] CPU: ARM64 Processor detected",
    "[    0.056789] Memory: 4096MB available",
    "[    0.089012] Initializing cgroup subsys",
    "[    0.123456] SELinux: Initializing.",
    "[    0.145623] Mounting root filesystem...",
    "[    0.178901] su: binary patched successfully",
    "[    0.201234] Root access granted: uid=0(root)",
    "[    0.234567] Starting init process...",
    "[    0.245123] Loading kernel modules...",
    "[    0.256789] Initializing network stack",
    "[    0.267890] Detecting hardware devices",
    "[    0.278901] Mounting /system partition",
    "[    0.289012] Mounting /data partition",
    "[    0.301234] Starting Zygote process",
    "[    0.312345] Initializing display driver",
    "[    0.323456] Loading GPU firmware",
    "[    0.334567] Starting audio service",
    "[    0.345678] Initializing sensors",
    "[    0.356789] Starting Bluetooth stack",
    "[    0.367890] Starting Wi-Fi driver",
    "[    0.378901] Checking filesystem integrity",
    "[    0.389012] Mounting external storage",
    "[    0.401234] Starting package manager",
    "[    0.412345] Verifying system signatures",
    "[    0.423456] Starting activity manager",
    "[    0.434567] Loading system services",
    "[    0.445678] Starting power management",
    "[    0.456789] System boot complete.",
  ];

  List<String> shown = [];
  int index = 0;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (index < bootLines.length) {
        setState(() {
          shown.add(bootLines[index]);
          index++;
        });
        Future.delayed(const Duration(milliseconds: 50), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeShell(
                selectedTheme: widget.selectedTheme,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          controller: scrollController,
          itemCount: shown.length,
          itemBuilder: (context, i) {
            return Text(
              shown[i],
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

class HomeShell extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Function(AppThemeColor) onThemeChanged;

  const HomeShell({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SystemInfoPage(),
      AppInfoPage(
        selectedTheme: widget.selectedTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
      const NotesPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          setState(() {
            currentIndex = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'Sistem',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Uygulama',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notlar',
          ),
        ],
      ),
    );
  }
}

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  String deviceModel = "Yükleniyor...";
  String batteryLevel = "Yükleniyor...";
  String batteryState = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    loadDeviceInfo();
    loadBatteryInfo();
  }

  Future<void> loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
      });
    } catch (e) {
      setState(() {
        deviceModel = "Alınamadı";
      });
    }
  }

  Future<void> loadBatteryInfo() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      final state = await battery.batteryState;
      setState(() {
        batteryLevel = "%$level";
        batteryState = state == BatteryState.charging
            ? "Şarj oluyor"
            : state == BatteryState.discharging
                ? "Şarj olmuyor"
                : "Bilinmiyor";
      });
    } catch (e) {
      setState(() {
        batteryLevel = "Alınamadı";
        batteryState = "Alınamadı";
      });
    }
  }

  Widget infoCard(BuildContext context, IconData icon, String title, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Sistem",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        infoCard(context, Icons.smartphone, "Cihaz Modeli", deviceModel),
        infoCard(context, Icons.battery_full, "Pil Yüzdesi", batteryLevel),
        infoCard(context, Icons.bolt, "Şarj Durumu", batteryState),
      ],
    );
  }
}

class AppInfoPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Function(AppThemeColor) onThemeChanged;

  const AppInfoPage({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String currentVersion = "";
  String? updateUrl;
  bool updateAvailable = false;
  bool downloading = false;

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  Future<void> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final local = packageInfo.version;
      setState(() {
        currentVersion = local;
      });

      final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/TechyTR/This-Linux/main/version.json',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remote = data['latest_version'] as String;
        final url = data['download_url'] as String;
        if (_isNewer(remote, local)) {
          setState(() {
            updateAvailable = true;
            updateUrl = url;
          });
        }
      }
    } catch (e) {
      // ses
