import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Outfit'; // Premium, modern heading font

  static TextStyle headingLarge(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle headingMedium(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle headingSmall(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color.withOpacity(0.8),
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color.withOpacity(0.6),
      );

  static TextStyle button(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );
}