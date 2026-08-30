import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateInfo {
  final String version;
  final String name;
  final String? downloadUrl;

  const UpdateInfo({
    required this.version,
    required this.name,
    this.downloadUrl,
  });
}

class UpdateService {
  static const String versionUrl =
      'https://raw.githubusercontent.com/TechyTR/ThisLinux-app/Version2/version.json';

  static Future<UpdateInfo?> checkForUpdate(
    String currentVersion,
  ) async {
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final latestVersion = data['version']?.toString();

      if (latestVersion == null || latestVersion.isEmpty) {
        return null;
      }

      if (_isNewerVersion(latestVersion, currentVersion)) {
        return UpdateInfo(
          version: latestVersion,
          name: data['name']?.toString() ?? 'New version',
          downloadUrl: data['downloadUrl']?.toString(),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isNewerVersion(
    String latest,
    String current,
  ) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      }

      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    final cleaned = version.replaceFirst('v', '');
    final parts = cleaned.split('.');

    return List.generate(
      3,
      (index) {
        if (index >= parts.length) {
          return 0;
        }

        return int.tryParse(parts[index]) ?? 0;
      },
    );
  }
}
