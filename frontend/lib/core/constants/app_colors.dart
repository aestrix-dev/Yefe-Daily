import 'package:flutter/material.dart';

class AppColors {
  // Static colors that never change
  static const Color primary1 = Color(0xFF1E231D); // Keep as requested
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF424242);

  // Status colors (usually static)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Theme-aware colors (change based on light/dark mode)
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A6B57) // Lighter version for dark mode
        : const Color(0xFF374035); // Original for light mode
  }

  static Color primaryDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E3B2C) // Darker for dark mode
        : const Color(0xFF1976D2); // Original for light mode
  }

  static Color primaryLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7A8A77) // Adjusted for dark mode
        : const Color(0xFFC1C4C0); // Original for light mode
  }

  static Color accentLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 38, 43, 38) // Dark grey for dark mode
        : const Color(0xFFEBECEB); // Original for light mode
  }

  static Color accentDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF171B16) // Very dark for dark mode
        : const Color(0xFFF5F1EA); // Original for light mode
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE1A3B3) // Adjusted for dark mode
        : const Color(0xFFC1C4C0); // Fixed the typo from original
  }

  static Color secondaryDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFD6CABC) // Darker for dark mode
        : const Color(0xFFD6CABC); // Fixed the typo from original
  }

  static Color secondaryLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF0C8A0) // Adjusted for dark mode
        : const Color(0xFFFFE0B2); // Original for light mode
  }

  static Color backgroundLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF000000) // True black for dark mode
        : const Color(0xFFFAFAFA); // Original for light mode
  }

  static Color backgroundDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212) // Original dark background
        : const Color(0xFFE0E0E0); // Light grey for light mode
  }

  static Color surfaceLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Dark surface
        : const Color(0xFFFFFFFF); // Original white surface
  }

  static Color surfaceDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Original dark surface
        : const Color(0xFFF0F0F0); // Light grey surface for light mode
  }

  // Text colors
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF) // White text for dark mode
        : const Color(0xFF000000); // Black text for light mode
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0) // Light grey text for dark mode
        : const Color(0xFF666666); // Dark grey text for light mode
  }

}
