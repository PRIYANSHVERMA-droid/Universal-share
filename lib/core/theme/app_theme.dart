import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ThemeConstants.darkBgColor,
      cardColor: ThemeConstants.darkCardColor,
      primaryColor: ThemeConstants.primaryGradient.first,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F2FE),
        secondary: Color(0xFF9B51E0),
        surface: ThemeConstants.darkCardColor,
        error: ThemeConstants.errorColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ThemeConstants.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          side: const BorderSide(color: ThemeConstants.darkGlassBorderColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: ThemeConstants.darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          side: const BorderSide(color: ThemeConstants.darkGlassBorderColor),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ThemeConstants.lightBgColor,
      cardColor: ThemeConstants.lightCardColor,
      primaryColor: ThemeConstants.primaryGradient.first,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4FACFE),
        secondary: Color(0xFF9B51E0),
        surface: ThemeConstants.lightCardColor,
        error: ThemeConstants.errorColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ThemeConstants.lightCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          side: const BorderSide(color: ThemeConstants.lightGlassBorderColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: ThemeConstants.lightCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          side: const BorderSide(color: ThemeConstants.lightGlassBorderColor),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}