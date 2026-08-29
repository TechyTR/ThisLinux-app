import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'This Linux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'monospace',
      ),
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

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
    "[    0.267890] System boot complete.",
  ];

  List<String> shown = [];
  int index = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (index < bootLines.length) {
        setState(() {
          shown.add(bootLines[index]);
          index++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PanelScreen()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          shown.join('\n'),
          style: const TextStyle(color: Colors.green, fontSize: 14),
        ),
      ),
    );
  }
}

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  String deviceModel = "Yükleniyor...";
  String ramInfo = "Yükleniyor...";
  String storageInfo = "Bilinmiyor";
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

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Kernel Panel",
          style: TextStyle(color: Colors.green),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            infoRow("Cihaz Modeli", deviceModel),
            infoRow("RAM", ramInfo),
            infoRow("Depolama", storageInfo),
            infoRow("Pil Yüzdesi", batteryLevel),
            infoRow("Şarj Durumu", batteryState),
          ],
        ),
      ),
    );
  }
}
