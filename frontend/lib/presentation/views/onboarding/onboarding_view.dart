import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/presentation/views/onboarding/widgets/onboarding_page.dart';
import 'package:yefa/presentation/views/onboarding/widgets/page_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../shared/widgets/custom_button.dart';
import 'onboarding_viewmodel.dart';


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
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: TextButton(
                  onPressed: viewModel.skipOnboarding,
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(fontSize: 16.sp, color: AppColors.grey),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: viewModel.pageController,
                onPageChanged: viewModel.onPageChanged,
                itemCount: viewModel.onboardingPages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    model: viewModel.onboardingPages[index],
                  );
                },
              ),
            ),

            PageIndicator(
              currentIndex: viewModel.currentIndex,
              pageCount: viewModel.onboardingPages.length,
            ),

            SizedBox(height: 40.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (viewModel.currentIndex > 0)
                    TextButton(
                      onPressed: viewModel.previousPage,
                      child: Text(
                        AppStrings.previous,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),

                  CustomButton(
                    text: viewModel.isLastPage
                        ? AppStrings.getStarted
                        : AppStrings.next,
                    onPressed: viewModel.isLastPage
                        ? viewModel.completeOnboarding
                        : viewModel.nextPage,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) =>
      OnboardingViewModel();
}
