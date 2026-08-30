import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;

  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const String versionUrl =
      'https://raw.githubusercontent.com/TechyTR/ThisLinux-app/main/version.json';

  static Future<UpdateInfo?> checkForUpdate(
    String currentVersion,
  ) async {
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final latestVersion =
          data['version']?.toString();

      final downloadUrl =
          data['download_url']?.toString();

      if (latestVersion == null ||
          downloadUrl == null ||
          latestVersion.isEmpty ||
          downloadUrl.isEmpty) {
        return null;
      }

      if (_isNewerVersion(
        currentVersion,
        latestVersion,
      )) {
        return UpdateInfo(
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isNewerVersion(
    String current,
    String latest,
  ) {
    final currentParts =
        _parseVersion(current);

    final latestParts =
        _parseVersion(latest);

    final length =
        currentParts.length >
                latestParts.length
            ? currentParts.length
            : latestParts.length;

    for (int i = 0; i < length; i++) {
      final currentValue =
          i < currentParts.length
              ? currentParts[i]
              : 0;

      final latestValue =
          i < latestParts.length
              ? latestParts[i]
              : 0;

      if (latestValue > currentValue) {
        return true;
      }

      if (latestValue < currentValue) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(
    String version,
  ) {
    return version
        .replaceFirst('v', '')
        .split('.')
        .map(
          (part) =>
              int.tryParse(part) ?? 0,
        )
        .toList();
  }
}
