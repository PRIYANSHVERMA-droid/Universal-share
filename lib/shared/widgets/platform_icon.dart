import 'package:flutter/material.dart';

class PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;
  final Color? color;

  const PlatformIcon({
    super.key,
    required this.platform,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.white;

    switch (platform.toLowerCase()) {
      case 'windows':
        iconData = Icons.desktop_windows_rounded;
        if (color == null) iconColor = const Color(0xFF0078D4); // Windows Blue
        break;
      case 'android':
        iconData = Icons.phone_android_rounded;
        if (color == null) iconColor = const Color(0xFF3DDC84); // Android Green
        break;
      case 'macos':
        iconData = Icons.laptop_mac_rounded;
        if (color == null) iconColor = const Color(0xFFA2AAAD); // Apple Silver
        break;
      case 'ios':
        iconData = Icons.phone_iphone_rounded;
        if (color == null) iconColor = const Color(0xFFFF2D55); // iOS Pink/Red
        break;
      default:
        iconData = Icons.devices_other_rounded;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}
