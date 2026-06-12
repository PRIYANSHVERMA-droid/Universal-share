import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Retrieves or generates a persistent, stable device UUID.
  String getDeviceId() {
    String? id = _prefs.getString(AppConstants.keyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(AppConstants.keyDeviceId, id);
    }
    return id;
  }

  /// Retrieves or sets a default device name (e.g., Computer name on Windows).
  String getDeviceName() {
    String? name = _prefs.getString(AppConstants.keyDeviceName);
    if (name == null || name.trim().isEmpty) {
      if (Platform.isWindows) {
        name = Platform.environment['COMPUTERNAME'] ?? 'Windows PC';
      } else if (Platform.isAndroid) {
        name = 'Android Phone';
      } else if (Platform.isMacOS) {
        name = 'Mac';
      } else if (Platform.isIOS) {
        name = 'iPhone';
      } else {
        name = 'Universal Share Device';
      }
      _prefs.setString(AppConstants.keyDeviceName, name);
    }
    return name;
  }

  Future<void> setDeviceName(String name) async {
    await _prefs.setString(AppConstants.keyDeviceName, name);
  }

  /// Retrieves the selected download folder. Fallback to native Downloads directory where available.
  Future<String> getDownloadPath() async {
    String? path = _prefs.getString(AppConstants.keyDownloadPath);
    
    // Check if we need to initialize or if the current path is a suboptimal default (like internal app docs)
    bool isSuboptimal = false;
    if (path != null && Platform.isAndroid) {
      // If it's in the app's internal data directory, it's suboptimal for a user-facing download folder
      if (path.contains('/data/user/0/') || path.contains('/data/data/')) {
        isSuboptimal = true;
      }
    }

    if (path == null || path.isEmpty || isSuboptimal) {
      Directory? dir;
      try {
        if (Platform.isWindows || Platform.isMacOS) {
          dir = await getDownloadsDirectory();
        } else if (Platform.isAndroid) {
          // Common paths for Android Downloads
          final List<String> candidatePaths = [
            '/storage/emulated/0/Download',
            '/sdcard/Download',
            '/storage/emulated/0/Downloads',
            '/sdcard/Downloads',
          ];

          for (final p in candidatePaths) {
            final d = Directory(p);
            if (await d.exists()) {
              dir = d;
              break;
            }
          }

          if (dir == null) {
            // Last resort for Android: app-specific external storage
            final extDir = await getExternalStorageDirectory();
            if (extDir != null) {
              dir = extDir;
            }
          }
        }
      } catch (_) {
        // Fallback if platform fails to resolve downloads dir
      }
      
      dir ??= await getApplicationDocumentsDirectory();
      path = dir.path;
      await _prefs.setString(AppConstants.keyDownloadPath, path);
    }
    return path;
  }

  Future<void> setDownloadPath(String path) async {
    await _prefs.setString(AppConstants.keyDownloadPath, path);
  }

  /// Theme mode: 'dark' (default) or 'light'
  String getThemeMode() {
    return _prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(AppConstants.keyThemeMode, mode);
  }

  /// Auto-accept transfers from trusted devices
  bool getAutoAccept() {
    return _prefs.getBool(AppConstants.keyAutoAccept) ?? false;
  }

  Future<void> setAutoAccept(bool val) async {
    await _prefs.setBool(AppConstants.keyAutoAccept, val);
  }
}
