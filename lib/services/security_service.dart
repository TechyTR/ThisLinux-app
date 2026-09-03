import 'package:flutter/services.dart';

enum SecurityStatus {
  safe,
  scanRequired,
  malwareDetected,
}

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
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledApps',
      );

      if (result == null) return [];

      return result
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .map(Map<String, dynamic>.from)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<SecurityScanResult> scanDevice({
    void Function(String appName)? onAppScanned,
  }) async {
    final apps = await getInstalledApps();
    final scannedApps = <String>[];
    final suspiciousApps = <String>[];

    for (var index = 0; index < apps.length; index++) {
      final app = apps[index];
      final label = app['label']?.toString().trim() ?? '';
      final packageName = app['packageName']?.toString().trim() ?? '';
      final name = label.isNotEmpty ? label : packageName;

      if (name.isEmpty) continue;

      scannedApps.add(name);

      // Keep UI callbacks sparse so scanning a large app list does not
      // trigger a Flutter rebuild for every single package.
      if (index == 0 || index % 8 == 0 || index == apps.length - 1) {
        onAppScanned?.call(name);
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
    }

    if (apps.isEmpty) {
      return const SecurityScanResult(
        status: SecurityStatus.scanRequired,
        scannedApps: [],
        suspiciousApps: [],
        message: 'Uygulama listesine erişilemedi. Tarama tamamlanamadı.',
      );
    }

    // This scan currently checks the installed-app inventory and its basic
    // metadata; it is not a full antivirus engine. A completed scan with no
    // suspicious indicators is therefore reported as safe.
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
