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
  "[    0.000000] Linux version 6.1.0",
  "[    0.012431] Command line initialized",
  "[    0.018742] CPU: Initializing processor",
  "[    0.024183] CPU0: Booting",
  "[    0.031592] Memory: Initializing memory manager",
  "[    0.039821] Kernel: Setting up virtual memory",
  "[    0.047215] Kernel: Initializing scheduler",
  "[    0.054638] Kernel: Starting system timers",
  "[    0.062741] ACPI: Initializing system",
  "[    0.071293] PCI: Probing hardware",
  "[    0.083412] USB: Initializing USB subsystem",
  "[    0.094821] Storage: Detecting devices",
  "[    0.107532] Storage: Mounting filesystem",
  "[    0.119843] Display: Initializing graphics",
  "[    0.132651] GPU: Initializing graphics processor",
  "[    0.145923] Audio: Initializing audio subsystem",
  "[    0.159421] Network: Initializing network stack",
  "[    0.172831] Security: Initializing security modules",
  "[    0.186542] Drivers: Loading hardware drivers",
  "[    0.201384] Services: Starting system services",
  "[    0.217532] System: Checking filesystem",
  "[    0.234821] System: Verifying system integrity",
  "[    0.251943] System: Integrity check passed",
  "[    0.269421] Runtime: Initializing application",
  "[    0.287631] UI: Preparing interface",
  "[    0.305821] UI: Loading components",
  "[    0.324512] System: Finalizing startup",
  "[    0.343821] Boot: Initialization complete",
  "[    0.362941] Boot: Starting application",
  "[    0.381532] Boot: Application ready",
];
