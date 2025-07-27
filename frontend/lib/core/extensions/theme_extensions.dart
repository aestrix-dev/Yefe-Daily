// Create this file: lib/core/extensions/theme_extensions.dart
import 'package:flutter/material.dart';
import 'package:yefa/presentation/shared/themes/light_theme.dart';

extension ThemeHelper on BuildContext {
  // Quick access to theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Quick access to your custom colors
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;

  // Quick access to common colors
  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.surface;
  Color get surfaceColor => colorScheme.surface;
  Color get textColor => colorScheme.onSurface;

  // Your custom app colors
  Color get accentLight => appColors.accentLight;
  Color get accentDark => appColors.accentDark;
  Color get textSecondary => appColors.textSecondary;

  // Quick access to text styles
  TextStyle? get headingLarge => theme.textTheme.headlineLarge;
  TextStyle? get headingMedium => theme.textTheme.headlineMedium;
  TextStyle? get bodyLarge => theme.textTheme.bodyLarge;
  TextStyle? get bodyMedium => theme.textTheme.bodyMedium;
}
