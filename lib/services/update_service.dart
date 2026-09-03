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

  static const String releaseUrl =
      'https://api.github.com/repos/TechyTR/ThisLinux-app/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(releaseUrl),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name']?.toString();
      final assets = data['assets'];

      if (tagName == null || tagName.isEmpty || assets is! List) {
        return null;
      }

      String? downloadUrl;
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;

        final name = asset['name']?.toString();
        final url = asset['browser_download_url']?.toString();

        if (name == 'app-release.apk' &&
            url != null &&
            Uri.tryParse(url)?.scheme == 'https') {
          downloadUrl = url;
          break;
        }
      }

      downloadUrl ??= data['html_url']?.toString();

      if (downloadUrl == null || downloadUrl.isEmpty) {
        return null;
      }

      final version = tagName.replaceFirst(RegExp(r'^v'), '').trim();

      if (version.isEmpty) {
        return null;
      }

      return UpdateInfo(
        latestVersion: version,
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
      final currentPart = i < current.length ? current[i] : 0;
      final latestPart = i < latest.length ? latest[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .trim()
        .replaceFirst(RegExp(r'^v'), '')
        .split('.')
        .map((part) {
          final match = RegExp(r'\d+').firstMatch(part);
          return int.tryParse(match?.group(0) ?? '0') ?? 0;
        })
        .toList();
  }

  static Future<void> downloadAndInstall(String downloadUrl) async {
    final uri = Uri.tryParse(downloadUrl);

    if (uri == null || uri.scheme != 'https') {
      throw PlatformException(
        code: 'INVALID_URL',
        message: 'APK URL geçersiz.',
      );
    }

    try {
      await _channel.invokeMethod(
        'downloadAndInstall',
        {'url': downloadUrl},
      );
    } on PlatformException {
      rethrow;
    } on MissingPluginException {
      throw PlatformException(
        code: 'NATIVE_UPDATER_MISSING',
        message: 'Android güncelleme bileşeni bulunamadı.',
      );
    }
  }
}
