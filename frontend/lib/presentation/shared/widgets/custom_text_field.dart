import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: 14.sp, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.grey),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: AppColors.greyLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: AppColors.greyLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }
}
