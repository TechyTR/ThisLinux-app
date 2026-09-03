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
      final result =
          await _channel.invokeMethod<List<dynamic>>(
        'getInstalledApps',
      );

      if (result == null) {
        return [];
      }

      return result
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(
                key.toString(),
                value,
              ),
            ),
          )
          .map((item) => Map<String, dynamic>.from(item))
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

    for (final app in apps) {
      final label =
          app['label']?.toString().trim() ?? '';

      final packageName =
          app['packageName']?.toString().trim() ?? '';

      final name = label.isNotEmpty
          ? label
          : packageName;

      if (name.isEmpty) continue;

      scannedApps.add(name);
      onAppScanned?.call(name);

      await Future<void>.delayed(
        const Duration(milliseconds: 25),
      );
    }

    if (apps.isEmpty) {
      return const SecurityScanResult(
        status: SecurityStatus.scanRequired,
        scannedApps: [],
        suspiciousApps: [],
        message:
            'Uygulama listesine erişilemedi. Tarama tamamlanamadı.',
      );
    }

    return SecurityScanResult(
      status: SecurityStatus.scanRequired,
      scannedApps: scannedApps,
      suspiciousApps: suspiciousApps,
      message:
          'Uygulama taraması tamamlandı. Tam kötü amaçlı yazılım analizi için Stellar Secure motoru gerekiyor.',
    );
  }
}
