import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class OnboardingPageThree extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingPageThree({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main image
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
                'assets/images/onboarding3.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 120.sp,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 60.h),

          // Heading
          Text(
            'Achieve Your Goals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
              height: 1.2,
            ),
          ),

          SizedBox(height: 24.h),

          // Description
          Text(
            'Turn your dreams into reality with daily motivation, progress tracking, and celebrating every milestone on your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.grey,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 60.h),

          // Continue button
          CustomButton(
            text: 'Continue',
            onPressed: onContinue,
            width: double.infinity,
            height: 56.h,
          ),
        ],
      ),
    );
  }
}
