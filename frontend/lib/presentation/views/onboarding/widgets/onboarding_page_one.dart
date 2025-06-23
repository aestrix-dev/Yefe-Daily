import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class OnboardingPageOne extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingPageOne({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Main image at center
          Container(
            width: 280.w,
            height: 280.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Image.asset(
                'assets/images/onboarding1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.task_alt,
                      size: 120.sp,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 60.h),

          // Main heading
          Text(
            'Welcome to Yefa Daily App',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
              height: 1.2,
            ),
          ),

          SizedBox(height: 24.h),

          // Subheading
          Text(
            'Your personal companion for daily motivation, task management, and achieving your goals one step at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.grey,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 60.h),

          // Get Started button
          CustomButton(
            text: 'Get Started',
            onPressed: onGetStarted,
            width: double.infinity,
            height: 56.h,
          ),
        ],
        ),
      ),
    );
  }
}
