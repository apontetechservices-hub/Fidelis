import 'package:flutter/material.dart';

class FidelisTheme {
  // Sacred art inspired palette
  static const Color deepRed = Color(0xFF8B1A1A);        // Cardinal red
  static const Color gold = Color(0xFFC5A55A);            // Liturgical gold
  static const Color ivory = Color(0xFFFFF8E7);           // Parchment
  static const Color darkBlue = Color(0xFF1A2332);        // Night sky
  static const Color softWhite = Color(0xFFFAFAFA);       // Soft white
  static const Color deepPurple = Color(0xFF3C2A5C);      // Liturgical purple
  static const Color forestGreen = Color(0xFF2D5A3D);     // Liturgical green

  // Light mode - soft, innocent palette
  static const Color lightBlue = Color(0xFFB8D4E3);     // Soft sky blue
  static const Color rosePink = Color(0xFFD4909F);     // Rose pink (darker for readability)
  static const Color softPink = Color(0xFFF5D5E0);     // Soft blush pink
  static const Color powderBlue = Color(0xFFD6E8F0);    // Powder blue
  static const Color warmWhite = Color(0xFFF8EDE3);        // Warm cream (distinct from rosePink nav)
  static const Color paleRose = Color(0xFFF5E4EC);      // Pale rose

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: rosePink,
      scaffoldBackgroundColor: warmWhite,
      colorScheme: const ColorScheme.light(
        primary: rosePink,
        secondary: lightBlue,
        surface: warmWhite,
        onPrimary: Color(0xFF5A3A4A),
        onSecondary: Color(0xFF3A4A5A),
        onSurface: Color(0xFF4A3A4A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: rosePink,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A3A4A)),
        headlineMedium: TextStyle(fontFamily: 'Cinzel', fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF4A3A4A)),
        titleLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 18, fontWeight: FontWeight.w600, color: rosePink),
        bodyLarge: TextStyle(fontFamily: 'Lora', fontSize: 16, color: Color(0xFF4A3A4A)),
        bodyMedium: TextStyle(fontFamily: 'Lora', fontSize: 14, color: Color(0xFF4A3A4A)),
        labelLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF4A3A4A)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: rosePink,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: rosePink,
        indicatorColor: Colors.white.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Colors.white70);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return const TextStyle(color: Colors.white70, fontSize: 12);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: gold,
      scaffoldBackgroundColor: darkBlue,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: deepRed,
        surface: Color(0xFF243447),
        onPrimary: darkBlue,
        onSecondary: softWhite,
        onSurface: softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF14202E),
        foregroundColor: gold,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF243447),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 28, fontWeight: FontWeight.bold, color: softWhite),
        headlineMedium: TextStyle(fontFamily: 'Cinzel', fontSize: 22, fontWeight: FontWeight.w600, color: gold),
        titleLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 18, fontWeight: FontWeight.w600, color: gold),
        bodyLarge: TextStyle(fontFamily: 'Lora', fontSize: 16, color: softWhite),
        bodyMedium: TextStyle(fontFamily: 'Lora', fontSize: 14, color: softWhite),
        labelLarge: TextStyle(fontFamily: 'Cinzel', fontSize: 14, fontWeight: FontWeight.w500, color: gold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF14202E),
        selectedItemColor: gold,
        unselectedItemColor: Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}