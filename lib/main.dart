import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

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
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (index < bootLines.length) {
        setState(() {
          shown.add(bootLines[index]);
          index++;
        });
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 300), () {
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
}class HomeShell extends StatefulWidget {
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
  bool updateAvailable = false;
  String? updateUrl;

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  Future<void> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final local = packageInfo.version;

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
      // sessizce geç
    }
  }

  bool _isNewer(String remote, String local) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final r = parse(remote);
    final l = parse(local);
    for (int i = 0; i < r.length; i++) {
      final lv = i < l.length ? l[i] : 0;
      if (r[i] > lv) return true;
      if (r[i] < lv) return false;
    }
    return false;
  }

  Widget navIcon(IconData icon, int index, Color activeColor) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? activeColor : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : activeColor,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      const SystemInfoPage(),
      AppInfoPage(
        selectedTheme: widget.selectedTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
      const NotesPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (updateAvailable)
              GestureDetector(
                onTap: () {
                  if (updateUrl != null) {
                    launchUrl(Uri.parse(updateUrl!),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.system_update, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Güncelleme hazır!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: pages[currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              navIcon(Icons.memory, 0, scheme.primary),
              navIcon(Icons.info, 1, scheme.primary),
              navIcon(Icons.sticky_note_2, 2, scheme.primary),
            ],
          ),
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  Future<void> loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      currentVersion = packageInfo.version;
    });
  }

  Widget themeSwatch(AppThemeColor theme) {
    final isSelected = widget.selectedTheme == theme;
    return GestureDetector(
      onTap: () => widget.onThemeChanged(theme),
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.seed : Colors.transparent,
          border: Border.all(color: theme.seed, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          theme.label,
          style: TextStyle(
            color: isSelected ? Colors.black : theme.seed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Uygulama",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text(
          "Tema",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          children: AppThemeColor.values.map(themeSwatch).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.primary),
              const SizedBox(width: 16),
              Text(
                "Sürüm v$currentVersion",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NoteItem {
  String text;
  NoteItem(this.text);

  Map<String, dynamic> toJson() => {'text': text};
  factory NoteItem.fromJson(Map<String, dynamic> json) =>
      NoteItem(json['text'] as String);
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<NoteItem> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('notes_list');
    if (saved != null) {
      final List decoded = json.decode(saved);
      setState(() {
        notes = decoded.map((e) => NoteItem.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(notes.map((e) => e.toJson()).toList());
    await prefs.setString('notes_list', encoded);
  }

  void addNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Not"),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Notunuzu yazın..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        notes.add(NoteItem(result.trim()));
      });
      saveNotes();
    }
  }

  void deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
    saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notlar",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        "Henüz not yok",
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, i) {
                        return Dismissible(
                          key: ValueKey(notes[i].hashCode.toString() + i.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => deleteNote(i),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(notes[i].text),
                          ),
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
