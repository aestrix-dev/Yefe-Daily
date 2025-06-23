import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

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
      body: SafeArea(
        child: PageView(
          controller: viewModel.pageController,
          onPageChanged: viewModel.onPageChanged,
          children: [
            // Page 1
            OnboardingPageOne(onGetStarted: viewModel.nextPage),

            // Page 2
            OnboardingPageTwo(onContinue: viewModel.nextPage),

            // Page 3
            OnboardingPageThree(onContinue: viewModel.completeOnboarding),
          ],
        ),
      ),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) =>
      OnboardingViewModel();
}
