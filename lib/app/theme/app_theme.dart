import 'package:flutter/material.dart';

class AppTheme {
  // Wood & Garden Palette
  static const Color woodDark = Color(0xFF5D3A1A);
  static const Color woodMedium = Color(0xFF8B5A2B);
  static const Color woodLight = Color(0xFFB57C3E);
  static const Color woodBorder = Color(0xFF42260E);
  
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF099);
  static const Color goldDark = Color(0xFFC69200);

  static const Color emeraldGreen = Color(0xFF4CAF50);
  static const Color greenLight = Color(0xFF76D275);
  static const Color greenDark = Color(0xFF2E7D32);

  static const Color glossyBlue = Color(0xFF2196F3);
  static const Color blueLight = Color(0xFF64B5F6);
  static const Color blueDark = Color(0xFF1565C0);

  static const Color creamBackground = Color(0xFFFFF8E7);
  static const Color creamCard = Color(0xFFFFFDF5);
  static const Color panelBorder = Color(0xFFD7CCC8);

  static const Color textPrimaryColor = Color(0xFF3E2723); // Deep Wood Brown
  static const Color textSecondaryColor = Color(0xFF795548);

  static const double borderRadius = 18.0;

  // Linear Gradients
  static const LinearGradient greenGlossyGradient = LinearGradient(
    colors: [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueGlossyGradient = LinearGradient(
    colors: [Color(0xFF64B5F6), Color(0xFF2196F3), Color(0xFF1565C0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient woodSignGradient = LinearGradient(
    colors: [Color(0xFFB57C3E), Color(0xFF8B5A2B), Color(0xFF5D3A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient woodCardGradient = LinearGradient(
    colors: [Color(0xFFFFF8E8), Color(0xFFF9EED4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGlossyGradient = LinearGradient(
    colors: [Color(0xFFFFEE58), Color(0xFFFFCA28), Color(0xFFFFA000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: woodMedium,
      scaffoldBackgroundColor: const Color(0xFF1E3A1E),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              offset: Offset(1, 2),
              blurRadius: 3,
            )
          ],
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: woodMedium,
        secondary: goldAccent,
        surface: creamCard,
      ),
    );
  }
}
