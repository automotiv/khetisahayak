
import 'package:flutter/material.dart';

class AppTheme {
  // New Dark Theme based on the provided image
  static final ThemeData newDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1C1C1E), // Dark background
    fontFamily: 'SF Pro Display', // Using a font that matches the modern look

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF34C759), // Vibrant green for accents
      secondary: Color(0xFF3A3A3C),
      surface: Color(0xFF2C2C2E), // Card background
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      background: Color(0xFF1C1C1E),
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, // Transparent to blend with body
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.bold, 
        color: Colors.white
      ),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF8E8E93)), // Lighter grey for subtitles
    ),

    // Card Theme
    // cardTheme: CardTheme(
    //   color: const Color(0xFF2C2C2E), // Dark card color
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(20), // Rounded corners
    //   ),
    // ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2E),
        selectedItemColor: Color(0xFF34C759),
        unselectedItemColor: Color(0xFF8E8E93),
        showSelectedLabels: false, // As per the design
        showUnselectedLabels: false,
    ),
  );

  // High Contrast Theme
  static final ThemeData highContrastTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    fontFamily: 'SF Pro Display',
    
    colorScheme: const ColorScheme.dark(
      primary: Colors.yellow, // High contrast yellow
      secondary: Colors.cyanAccent, // High contrast cyan
      surface: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      background: Colors.black,
      error: Colors.redAccent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.bold, 
        color: Colors.white
      ),
      iconTheme: IconThemeData(color: Colors.yellow),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellow),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.black,
      labelStyle: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.yellow, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
    ),
  );
}
