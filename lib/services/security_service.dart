import 'dart:io';

import 'package:flutter/services.dart';

enum SecurityStatus { safe, scanRequired, malwareDetected }

class SecurityScanResult {
  final SecurityStatus status;
  final List<String> scannedApps;
  final List<String> suspiciousApps;
  final String message;

  const SecurityScanResult({
    required this.status,
    required this.scannedApps,
    required this.suspiciousApps,
    required this.message,
  });
}

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return const [];
      return result.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> checkRootAccess() async {
    try {
      final process = await Process.run(
        'su',
        const ['-c', 'id'],
        runInShell: false,
      ).timeout(const Duration(seconds: 3));
      final output = '${process.stdout} ${process.stderr}'.toString();
      if (process.exitCode == 0 && RegExp(r'uid=0\b').hasMatch(output)) {
        return true;
      }
    } catch (_) {}

    try {
      return await _channel.invokeMethod<bool>('checkRoot') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<SecurityScanResult> scanDevice({
    void Function(String appName)? onAppScanned,
  }) async {
    final apps = await getInstalledApps();

    if (apps.isEmpty) {
      return const SecurityScanResult(
        status: SecurityStatus.scanRequired,
        scannedApps: [],
        suspiciousApps: [],
        message: 'Uygulama listesine erişilemedi. Tarama tamamlanamadı.',
      );
    }

    final scannedApps = <String>[];
    final suspiciousApps = <String>[];

    // Keep the scan responsive on low-end and old Android devices. The budget
    // is intentionally below two minutes so UI/OS overhead has headroom.
    const scanBudgetMs = 116000;
    final perAppMs = (scanBudgetMs ~/ apps.length).clamp(12, 120);

    for (var index = 0; index < apps.length; index++) {
      final app = apps[index];
      final label = app['label']?.toString().trim() ?? '';
      final packageName = app['packageName']?.toString().trim() ?? '';
      final name = label.isNotEmpty ? label : packageName;
      if (name.isEmpty) continue;

      scannedApps.add(name);

      // Lightweight metadata heuristic only. This is not a full antivirus
      // engine and must not be presented as guaranteed malware detection.
      final metadata = '${label.toLowerCase()} ${packageName.toLowerCase()}';
      if (metadata.contains('malware') ||
          metadata.contains('trojan') ||
          metadata.contains('virus')) {
        suspiciousApps.add(name);
      }

      if (index == 0 || index % 8 == 0 || index == apps.length - 1) {
        onAppScanned?.call(name);
      }

      await Future<void>.delayed(Duration(milliseconds: perAppMs));
    }

    final status = suspiciousApps.isEmpty
        ? SecurityStatus.safe
        : SecurityStatus.malwareDetected;

    return SecurityScanResult(
      status: status,
      scannedApps: List.unmodifiable(scannedApps),
      suspiciousApps: List.unmodifiable(suspiciousApps),
      message: suspiciousApps.isEmpty
          ? 'Tarama tamamlandı. Şüpheli uygulama göstergesi bulunamadı.'
          : 'Tarama tamamlandı. Şüpheli uygulama göstergeleri bulundu.',
    );
  }
}
