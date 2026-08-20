import 'package:flutter/material.dart';

class AppTheme {
  // Theme Color Palette
  static const Color backgroundColor = Color(0xFF0F172A); // Dark Slate 900
  static const Color surfaceColor = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceLightColor = Color(0xFF334155); // Slate 700
  
  static const Color primaryColor = Color(0xFF0D9488);    // Teal 600
  static const Color primaryGlow = Color(0xFF14B8A6);     // Teal 500
  static const Color secondaryColor = Color(0xFF0EA5E9);  // Sky 500
  
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color textMuted = Color(0xFF64748B);       // Slate 500
  
  static const Color successColor = Color(0xFF10B981);    // Emerald 500
  static const Color errorColor = Color(0xFFEF4444);      // Red 500
  static const Color warningColor = Color(0xFFF59E0B);    // Amber 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [primaryGlow, Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGlow, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Selection Theme
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryGlow,
        selectionColor: Color(0xFF0D9488),
        selectionHandleColor: primaryGlow,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
