import 'dart:convert';

import 'package:flutter/services.dart';
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
  static const MethodChannel _channel =
      MethodChannel('thislinux/updater');

  static const String versionUrl =
      'https://raw.githubusercontent.com/TechyTR/ThisLinux-app/main/version.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final latestVersion =
          data['latest_version']?.toString();

      final downloadUrl =
          data['download_url']?.toString();

      if (latestVersion == null ||
          latestVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty) {
        return null;
      }

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static bool isNewerVersion(
    String currentVersion,
    String latestVersion,
  ) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);

    final maxLength = current.length > latest.length
        ? current.length
        : latest.length;

    for (var i = 0; i < maxLength; i++) {
      final currentPart =
          i < current.length ? current[i] : 0;

      final latestPart =
          i < latest.length ? latest[i] : 0;

      if (latestPart > currentPart) {
        return true;
      }

      if (latestPart < currentPart) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .trim()
        .replaceFirst(RegExp(r'^v'), '')
        .split('.')
        .map((part) {
          final match =
              RegExp(r'\d+').firstMatch(part);

          return int.tryParse(
                match?.group(0) ?? '0',
              ) ??
              0;
        })
        .toList();
  }

  static Future<void> downloadAndInstall(
    String downloadUrl,
  ) async {
    await _channel.invokeMethod(
      'downloadAndInstall',
      {
        'url': downloadUrl,
      },
    );
  }
}
