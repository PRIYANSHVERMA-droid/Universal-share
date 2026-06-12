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
}
