import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class AppUpdateInfo {
  final String latestVersion;
  final String changelog;
  final String releaseUrl;
  final String? downloadUrl;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.changelog,
    required this.releaseUrl,
    this.downloadUrl,
    required this.hasUpdate,
  });
}

class UpdateService {
  static const String currentVersion = "1.0.0";
  static const String repoOwner = "priyanshverma-droid";
  static const String repoName = "Universal-share";

  Future<AppUpdateInfo> checkForUpdates() async {
    try {
      final url = Uri.parse("https://api.github.com/repos/$repoOwner/$repoName/releases/latest");
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode != 200) {
        return AppUpdateInfo(
          latestVersion: currentVersion,
          changelog: "",
          releaseUrl: "",
          hasUpdate: false,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? 'No release notes provided.';
      final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$repoOwner/$repoName/releases';

      // Parse version name
      final parsedTagName = tagName.replaceAll(RegExp(r'[^0-9.]'), ''); // e.g. "v1.0.1" -> "1.0.1"
      final isNewer = _isVersionNewer(currentVersion, parsedTagName);

      String? downloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        // Match asset for the platform
        if (Platform.isAndroid) {
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );
          if (apkAsset != null) {
            downloadUrl = apkAsset['browser_download_url'] as String?;
          }
        } else if (Platform.isWindows) {
          final winAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.zip') || (asset['name'] as String).endsWith('.exe'),
            orElse: () => null,
          );
          if (winAsset != null) {
            downloadUrl = winAsset['browser_download_url'] as String?;
          }
        }
      }

      return AppUpdateInfo(
        latestVersion: tagName,
        changelog: body,
        releaseUrl: htmlUrl,
        downloadUrl: downloadUrl ?? htmlUrl,
        hasUpdate: isNewer,
      );
    } catch (_) {
      return AppUpdateInfo(
        latestVersion: currentVersion,
        changelog: "",
        releaseUrl: "",
        hasUpdate: false,
      );
    }
  }

  bool _isVersionNewer(String current, String latest) {
    if (latest.isEmpty) return false;
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (var i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) {
          return latestParts[i] > 0;
        }
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

// Riverpod Provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});
