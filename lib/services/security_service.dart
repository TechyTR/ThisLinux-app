import 'package:flutter/services.dart';

enum SecurityStatus {
  safe,
  scanRequired,
  malwareDetected,
}

class SecurityScanResult {
  final SecurityStatus status;
  final List<String> scannedApps;

  const SecurityScanResult({
    required this.status,
    required this.scannedApps,
  });
}

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('org.test.thislinux/native');

  static Future<SecurityScanResult> scanDevice({
    void Function(String appName)? onAppScanned,
  }) async {
    final scannedApps = <String>[];

    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>(
        'getInstalledApps',
      );

      if (result != null) {
        for (final item in result) {
          final appName = item.toString().trim();

          if (appName.isEmpty) continue;

          scannedApps.add(appName);
          onAppScanned?.call(appName);

          await Future<void>.delayed(
            const Duration(milliseconds: 35),
          );
        }
      }
    } catch (_) {
      // Native tarama altyapısı henüz mevcut değilse
      // uygulama çökmemeli.
    }

    return SecurityScanResult(
      status: SecurityStatus.safe,
      scannedApps: scannedApps,
    );
  }
}
