import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show splash for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      final hasSeenOnboarding = viewModel.hasSeenOnboarding;
      final isLoggedIn = viewModel.isLoggedIn;

      print('SplashView: hasSeenOnboarding = $hasSeenOnboarding');
      print('SplashView: isLoggedIn = $isLoggedIn');

      // Navigation logic
      if (!hasSeenOnboarding) {
        // First time user - show onboarding
        print('SplashView: Navigating to onboarding');
        context.pushReplacement(AppRoutes.onboarding);
      } else {
        // Logged in user - go to home
        print('SplashView: Navigating to home');
        context.pushReplacement(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [ 
          // Logo centered on the screen
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 150.w,
              height: 198.h,
            ),
          ),
        ],
      ),
    );
  }

  @override
  SplashViewModel viewModelBuilder(BuildContext context) => SplashViewModel();
}
