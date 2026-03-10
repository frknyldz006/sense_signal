import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0C10);
  static const Color neonGreen = Color(0xFF39FF14);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        background: background,
        surface: Color(0x2239FF14),
      ),
      fontFamily: 'monospace',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xCC39FF14)),
        bodySmall: TextStyle(color: Color(0x8839FF14)),
        titleMedium: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
      ),
    );
  }
}
