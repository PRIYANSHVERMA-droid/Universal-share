import 'package:flutter/material.dart';

class ThemeConstants {
  // Brand Colors (Vibrant Cyber/Glassmorphism theme)
  static const Color darkBgColor = Color(0xFF0D111D); // Deep cyber navy
  static const Color darkCardColor = Color(0xFF161C2C); // Glass card fill
  static const Color darkGlassBorderColor = Color(0xFF2E384E); // Translucent borders
  
  static const Color lightBgColor = Color(0xFFF8FAFC); // Clean slate grey
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightGlassBorderColor = Color(0xFFE2E8F0);
  
  // Vibrant gradients for active states (radar, buttons, progress)
  static const List<Color> primaryGradient = [
    Color(0xFF00F2FE), // Electric Cyan
    Color(0xFF4FACFE), // Bright Blue
    Color(0xFF9B51E0), // Deep Violet
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFF355DA), // Cyber Pink
    Color(0xFF7000FF), // Neon Purple
  ];

  // Status Colors
  static const Color successColor = Color(0xFF00E676); // Emerald Green
  static const Color warningColor = Color(0xFFFFA000); // Amber Orange
  static const Color errorColor = Color(0xFFFF1744); // Neon Red
  static const Color infoColor = Color(0xFF2979FF); // Electric Blue

  // Spacing & Borders
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusSmall = 8.0;

  // Blur strengths for glassmorphism
  static const double glassBlurX = 20.0;
  static const double glassBlurY = 20.0;
}