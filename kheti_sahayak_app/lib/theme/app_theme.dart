
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

  // Keeping the old themes just in case, but they won't be used for now.
  static final ThemeData lightTheme = newDarkTheme; // Defaulting to dark
  static final ThemeData darkTheme = newDarkTheme;
}
