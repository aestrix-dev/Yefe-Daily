import 'package:flutter/material.dart';
import 'light_theme.dart'; // Import for AppColorsExtension

class DarkTheme {
  static ThemeData get theme {
    const primaryColor = Color(0xFF4CAF50);
    const primaryLight = Color(0xFF81C784);
    const backgroundColor = Color(0xFF121212);
    const surfaceColor = Color(0xFF1E1E1E);
    const accentLight = Color(0xFF2C2C2E);
    const accentDark = Color(0xFF1C1C1E);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Lato',
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),

      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Lato',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.grey[700];
        }),
      ),

      // Custom extension for your app colors
      extensions: [
        AppColorsExtension(
          accentLight: accentLight,
          accentDark: accentDark,
          textSecondary: Colors.grey[400]!,
        ),
      ],
    );
  }
}
