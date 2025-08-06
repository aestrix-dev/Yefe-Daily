import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class OnboardingPageOne extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingPageOne({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Content on top
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main image at center
              SizedBox(height: 70.h),
              SizedBox(
                width: 300.w,
                height: 300.h,
                child: ClipRRect(
                  child: Image.asset(
                    'assets/images/onboarding1.png',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight(
                            context,
                          ).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.task_alt,
                          size: 120.sp,
                          color: AppColors.primary1,
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              // Main heading
              Text(
                'Welcome to Yefa Daily App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary(context),
                  height: 1.2,
                ),
              ),

              SizedBox(height: 10.h),

              // Subheading
              Text(
                'A space for the modern man to reflect, grow, and rise — one day at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.grey,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 60.h),

              // Get Started button
              CustomButton(
                text: 'Get Started',
                onPressed: onGetStarted,
                width: double.infinity,
                height: 50.h,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
