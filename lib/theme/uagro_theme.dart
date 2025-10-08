// 🎨 TEMA INSTITUCIONAL UAGRO
// Colores y estilos oficiales

import 'package:flutter/material.dart';

class UAGroColors {
  // Colores institucionales UAGro
  static const Color primary = Color(0xFF0175C2);      // Azul UAGro
  static const Color secondary = Color(0xFFFFD700);    // Dorado UAGro
  static const Color background = Color(0xFFF8FAFC);   // Fondo claro
  static const Color surface = Color(0xFFFFFFFF);      // Superficie
  static const Color error = Color(0xFFDC2626);        // Error rojo
  static const Color success = Color(0xFF059669);      // Verde éxito
  static const Color warning = Color(0xFFF59E0B);      // Naranja advertencia
  
  // Texto
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF1F2937);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onError = Color(0xFFFFFFFF);
}

class UAGroTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: UAGroColors.primary,
        secondary: UAGroColors.secondary,
        background: UAGroColors.background,
        surface: UAGroColors.surface,
        error: UAGroColors.error,
        onPrimary: UAGroColors.onPrimary,
        onSecondary: UAGroColors.onSecondary,
        onBackground: UAGroColors.onBackground,
        onSurface: UAGroColors.onSurface,
        onError: UAGroColors.onError,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: UAGroColors.primary,
        foregroundColor: UAGroColors.onPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: UAGroColors.onPrimary,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: UAGroColors.surface,
      ),
      
      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UAGroColors.primary,
          foregroundColor: UAGroColors.onPrimary,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UAGroColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UAGroColors.error),
        ),
        filled: true,
        fillColor: UAGroColors.surface,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: UAGroColors.background,
    );
  }
}