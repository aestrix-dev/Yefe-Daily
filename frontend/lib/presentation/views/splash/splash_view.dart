import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'splash_viewmodel.dart';

class SplashView extends StackedView<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget builder(
    BuildContext context,
    SplashViewModel viewModel,
    Widget? child,
  ) {
    // Call handleStartup when the view is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.handleStartup();
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flutter_dash,
                size: 60.sp,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 40.h),

            Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20.h),

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  SplashViewModel viewModelBuilder(BuildContext context) => SplashViewModel();
}
