import 'package:flutter/material.dart';

class AppTheme {
  // A premium casual puzzle game visual direction
  static const Color primaryColor = Color(0xFF8A2BE2); // Vibrant Purple
  static const Color secondaryColor = Color(0xFFFFD700); // Glossy Gold
  static const Color backgroundColor = Color(0xFFF0F4F8); // Soft Light Blue
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2C3E50); // Dark Blue Grey
  static const Color textSecondaryColor = Color(0xFF7F8C8D);

  static const double borderRadius = 24.0;

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 32),
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 6,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )
      ),
    );
  }

  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      margin: const EdgeInsets.all(8.0),
    );
  }
}

