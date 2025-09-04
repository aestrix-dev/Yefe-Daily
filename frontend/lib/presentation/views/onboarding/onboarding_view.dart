import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import 'onboarding_viewmodel.dart';
import 'widgets/onboarding_page_one.dart';
import 'widgets/onboarding_page_two.dart';
import 'widgets/onboarding_page_three.dart';

class OnboardingView extends StackedView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  Widget builder(
    BuildContext context,
    OnboardingViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.primary1,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        bottom: false, 
        left: false, 
        right: false,
        child: PageView(
          controller: viewModel.pageController,
          onPageChanged: viewModel.onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Page 1
            OnboardingPageOne(onGetStarted: viewModel.nextPage),

            // Page 2
            OnboardingPageTwo(
              onContinue: viewModel.nextPage,
              onBack: viewModel.previousPage,
            ),

            // Page 3
            OnboardingPageThree(
              onContinue: () => viewModel.completeOnboarding(context),
              onBack: viewModel.previousPage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) =>
      OnboardingViewModel();
}
