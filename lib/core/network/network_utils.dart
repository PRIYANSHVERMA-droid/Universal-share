import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtils {
  static final NetworkInfo _networkInfo = NetworkInfo();

  static Future<String?> getLocalIpAddress() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }
    } catch (_) {}

    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<String?> getSubnetMask() async {
    try {
      return await _networkInfo.getWifiSubmask();
    } catch (_) {
      return null;
    }
  }

  static String? getBroadcastAddress(String ip, String subnetMask) {
    final ipParts = ip.split('.').map(int.parse).toList();
    final maskParts = subnetMask.split('.').map(int.parse).toList();

    if (ipParts.length != 4 || maskParts.length != 4) return null;

    final broadcastParts = <int>[];
    for (int i = 0; i < 4; i++) {
      broadcastParts.add(ipParts[i] | (~maskParts[i] & 0xFF));
    }

    return broadcastParts.join('.');
  }

  static bool isSameSubnet(String ip1, String ip2, String subnetMask) {
    final parts1 = ip1.split('.').map(int.parse).toList();
    final parts2 = ip2.split('.').map(int.parse).toList();
    final maskParts = subnetMask.split('.').map(int.parse).toList();

    if (parts1.length != 4 || parts2.length != 4 || maskParts.length != 4) {
      return false;
    }

    for (int i = 0; i < 4; i++) {
      if ((parts1[i] & maskParts[i]) != (parts2[i] & maskParts[i])) {
        return false;
      }
    }
    return true;
  }
}