import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData get theme {
    const primaryColor = Color(0xFF374035);
    const primaryLight = Color(0xFFC1C4C0);
    const backgroundColor = Color(0xFFFAFAFA);
    const surfaceColor = Color(0xFFFFFFFF);
    const accentLight = Color(0xFFEBECEB);
    const accentDark = Color(0xFFF5F1EA);
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Lato',
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
      ),
      
      scaffoldBackgroundColor: backgroundColor,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
     
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.grey[300];
        }),
      ),
      
      // Custom extension for your app colors
      extensions: [
        AppColorsExtension(
          accentLight: accentLight,
          accentDark: accentDark,
          textSecondary: Colors.grey[600]!,
        ),
      ],
    );
  }
}


// Custom theme extension for your app-specific colors
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color accentLight;
  final Color accentDark;
  final Color textSecondary;

  const AppColorsExtension({
    required this.accentLight,
    required this.accentDark,
    required this.textSecondary,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? accentLight,
    Color? accentDark,
    Color? textSecondary,
  }) {
    return AppColorsExtension(
      accentLight: accentLight ?? this.accentLight,
      accentDark: accentDark ?? this.accentDark,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    
    return AppColorsExtension(
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}