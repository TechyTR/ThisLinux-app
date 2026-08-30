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
          .get(
            Uri.parse(versionUrl),
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(
            response.body,
          ) as Map<String, dynamic>;

      final remoteVersion =
          data['latest_version']
              ?.toString();

      final downloadUrl =
          data['download_url']
              ?.toString();

      if (remoteVersion == null ||
          remoteVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty) {
        return null;
      }

      if (!_isNewer(
        remoteVersion,
        currentVersion,
      )) {
        return null;
      }

      return UpdateInfo(
        latestVersion:
            remoteVersion,
        downloadUrl:
            downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(
    String remote,
    String local,
  ) {
    final remoteParts =
        _parseVersion(remote);

    final localParts =
        _parseVersion(local);

    for (int i = 0; i < 3; i++) {
      if (remoteParts[i] >
          localParts[i]) {
        return true;
      }

      if (remoteParts[i] <
          localParts[i]) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(
    String version,
  ) {
    final cleaned =
        version
            .trim()
            .replaceFirst(
              RegExp(r'^[vV]'),
              '',
            );

    final parts =
        cleaned.split('.');

    return List.generate(
      3,
      (index) {
        if (index >=
            parts.length) {
          return 0;
        }

        final number =
            RegExp(
          r'^\d+',
        ).firstMatch(
          parts[index],
        );

        return int.tryParse(
              number?.group(0) ??
                  '',
            ) ??
            0;
      },
    );
  }
}
