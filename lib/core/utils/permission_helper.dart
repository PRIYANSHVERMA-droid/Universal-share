import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request permissions needed for mDNS / Local Peer discovery.
  /// On Android 13+, this requests NEARBY_WIFI_DEVICES.
  /// On older Android versions, it falls back to Location.
  static Future<bool> requestDiscoveryPermissions() async {
    if (!Platform.isAndroid) return true;

    // Check SDK version implicitly by requesting NEARBY_WIFI_DEVICES first
    final nearbyStatus = await Permission.nearbyWifiDevices.request();
    if (nearbyStatus.isGranted) {
      return true;
    }

    // Fallback for older Android devices which require location to do Wi-Fi/multicast scanning
    final locationStatus = await Permission.location.request();
    return locationStatus.isGranted;
  }

  /// Request permission to post notifications (mainly for Android 13+ transfer alerts).
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Returns true if the app has necessary permissions already
  static Future<bool> hasDiscoveryPermissions() async {
    if (!Platform.isAndroid) return true;
    final nearby = await Permission.nearbyWifiDevices.isGranted;
    final location = await Permission.location.isGranted;
    return nearby || location;
  }

  /// Request storage permissions.
  /// On Android 11+, we might need MANAGE_EXTERNAL_STORAGE for arbitrary folder access,
  /// but for Downloads folder specifically, WRITE_EXTERNAL_STORAGE (up to API 29) 
  /// and Scoped Storage handling is usually preferred.
  /// However, for a file transfer app, MANAGE_EXTERNAL_STORAGE is often used for simplicity if targetSdk is high.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isRestricted) {
      // Fallback for older versions or if MANAGE_EXTERNAL_STORAGE is not available
      final status = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
      return status.values.every((s) => s.isGranted);
    }

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // Fallback for Android 10 and below
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}
