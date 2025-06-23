import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  static ThemeData get lightTheme => LightTheme.theme;
  static ThemeData get darkTheme => DarkTheme.theme;

  // Updated text styles with Lato font
  static TextStyle get headingLarge => TextStyle(
    fontFamily: 'Lato',
    fontSize: 32.sp,
    fontWeight: FontWeight.w900, 
  );

  static TextStyle get headingMedium => TextStyle(
    fontFamily: 'Lato',
    fontSize: 24.sp,
    fontWeight: FontWeight.w700, 
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Lato',
    fontSize: 16.sp,
    fontWeight: FontWeight.w400, 
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Lato',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400, 
  );

  static TextStyle get caption => TextStyle(
    fontFamily: 'Lato',
    fontSize: 12.sp,
    fontWeight: FontWeight.w300, 
  );

  static TextStyle get button => TextStyle(
    fontFamily: 'Lato',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600, 
  );
}
