class AppConstants {
  static const String appName = 'Universal Share';
  
  // mDNS Discovery configuration
  static const String mdnsServiceType = '_universalshare._tcp';
  
  // Fallback Ports
  static const int defaultServerPort = 53317;
  static const int maxServerPortRange = 53327; // Scan ports from 53317 to 53327 if occupied
  static const int udpBroadcastPort = 53318;
  
  // Network protocols configuration
  static const Duration udpBroadcastInterval = Duration(seconds: 3);
  static const Duration peerExpiryDuration = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 5);
  
  // Storage keys
  static const String keyDeviceId = 'us_device_id';
  static const String keyDeviceName = 'us_device_name';
  static const String keyDownloadPath = 'us_download_path';
  static const String keyThemeMode = 'us_theme_mode';
  static const String keyTrustedDevices = 'us_trusted_devices';
  static const String keyAutoAccept = 'us_auto_accept';
}