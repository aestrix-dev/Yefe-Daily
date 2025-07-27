// ignore_for_file: use_build_context_synchronously

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 3));

      final hasSeenOnboarding = viewModel.hasSeenOnboarding;

      if (!hasSeenOnboarding) {
        context.pushReplacement(AppRoutes.onboarding);
      } else {
        context.pushReplacement(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary1,
      body: Stack(
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

         
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 200.w,
              height: 298.h,
            ),
          ),
        ],
      ),
    );
  }

  @override
  SplashViewModel viewModelBuilder(BuildContext context) => SplashViewModel();
}
