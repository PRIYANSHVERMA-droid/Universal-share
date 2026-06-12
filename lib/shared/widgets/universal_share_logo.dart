import 'package:flutter/material.dart';

class UniversalShareLogo extends StatelessWidget {
  final double size;
  final String? platform;
  final bool transparentBg;

  const UniversalShareLogo({
    super.key,
    this.size = 40.0,
    this.platform,
    this.transparentBg = false,
  });

  @override
  Widget build(BuildContext context) {
    Color platformColor;
    switch (platform?.toLowerCase()) {
      case 'windows':
        platformColor = const Color(0xFF0078D4);
        break;
      case 'android':
        platformColor = const Color(0xFF3DDC84);
        break;
      case 'ios':
        platformColor = const Color(0xFFFF2D55);
        break;
      case 'macos':
        platformColor = const Color(0xFFA2AAAD);
        break;
      default:
        platformColor = const Color(0xFF00F2FE);
    }

    final logoImage = Image.asset(
      'assets/icons/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback placeholder
        return Icon(
          Icons.share_rounded,
          size: size * 0.6,
          color: platformColor,
        );
      },
    );

    if (transparentBg) {
      return logoImage;
    }

    // Premium squircle/rounded container with border and glow matching the platform color
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color: const Color(0xFF0D1221), // dark cyber navy background matching theme
        border: Border.all(
          color: platformColor.withOpacity(0.4),
          width: size * 0.04,
        ),
        boxShadow: [
          BoxShadow(
            color: platformColor.withOpacity(0.25),
            blurRadius: size * 0.2,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: Center(
        child: logoImage,
      ),
    );
  }
}
