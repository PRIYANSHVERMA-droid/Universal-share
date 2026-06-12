import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TrustedDeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String fingerprint;
  final DateTime addedAt;

  TrustedDeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.fingerprint,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'fingerprint': fingerprint,
        'addedAt': addedAt.toIso8601String(),
      };

  factory TrustedDeviceInfo.fromJson(Map<String, dynamic> json) => TrustedDeviceInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String,
        fingerprint: json['fingerprint'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class TrustedDevicesRepository {
  final SharedPreferences _prefs;

  TrustedDevicesRepository(this._prefs);

  /// Load all trusted devices.
  List<TrustedDeviceInfo> getTrustedDevices() {
    final rawString = _prefs.getString(AppConstants.keyTrustedDevices);
    if (rawString == null || rawString.isEmpty) return [];

    try {
      final Map<String, dynamic> jsonMap = json.decode(rawString);
      return jsonMap.values
          .map((item) => TrustedDeviceInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Check if a device is trusted and matches the certificate fingerprint.
  bool isDeviceTrusted(String deviceId, String? currentFingerprint) {
    if (currentFingerprint == null) return false;
    
    final devices = getTrustedDevices();
    for (final device in devices) {
      if (device.id == deviceId) {
        // Fingerprint verification ensures peer cannot be spoofed
        return device.fingerprint.trim().toUpperCase() ==
            currentFingerprint.trim().toUpperCase();
      }
    }
    return false;
  }

  /// Mark a device as trusted and persist its certificate fingerprint.
  Future<void> addTrustedDevice(
    String deviceId,
    String name,
    String platform,
    String fingerprint,
  ) async {
    final devices = getTrustedDevices();
    final updatedDevices = devices.where((d) => d.id != deviceId).toList();
    
    updatedDevices.add(
      TrustedDeviceInfo(
        id: deviceId,
        name: name,
        platform: platform,
        fingerprint: fingerprint,
      ),
    );

    await _save(updatedDevices);
  }

  /// Revoke trust for a device.
  Future<void> removeTrustedDevice(String deviceId) async {
    final devices = getTrustedDevices();
    final updatedDevices = devices.where((d) => d.id != deviceId).toList();
    await _save(updatedDevices);
  }

  Future<void> _save(List<TrustedDeviceInfo> list) async {
    final Map<String, dynamic> jsonMap = {};
    for (final item in list) {
      jsonMap[item.id] = item.toJson();
    }
    await _prefs.setString(AppConstants.keyTrustedDevices, json.encode(jsonMap));
  }
}
