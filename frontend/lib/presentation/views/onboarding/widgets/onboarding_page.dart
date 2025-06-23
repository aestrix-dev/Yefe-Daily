import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/data/model/onboarding_model.dart';

import '../../../../core/constants/app_colors.dart';


class OnboardingPage extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, size: 100.sp, color: AppColors.primary),
          ),

          SizedBox(height: 60.h),

          Text(
            model.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),

          SizedBox(height: 20.h),

          Text(
            model.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
