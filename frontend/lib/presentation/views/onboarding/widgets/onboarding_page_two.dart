import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../onboarding_viewmodel.dart';

class OnboardingPageTwo extends ViewModelWidget<OnboardingViewModel> {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingPageTwo({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, OnboardingViewModel viewModel) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
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
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                // Back button section
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.accentDark(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18.sp,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // Card section - flexible height
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.accentDark(context),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              "Let's personalize your journey",
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                                height: 1.2,
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Email field
                            Text(
                              'Email address',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            CustomTextField(
                              hintText: 'Enter email address',
                              initialValue: viewModel.email,
                              onChanged: viewModel.setEmail,
                            ),

                            SizedBox(height: 24.h),

                            // Name field
                            Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            CustomTextField(
                              hintText: 'Enter name',
                              initialValue: viewModel.name,
                              onChanged: viewModel.setName,
                            ),

                            SizedBox(height: 24.h),

                            // Password field
                            // Text(
                            //   'Password',
                            //   style: TextStyle(
                            //     fontSize: 16.sp,
                            //     fontWeight: FontWeight.w600,
                            //     color: AppColors.black,
                            //   ),
                            // ),
                            // SizedBox(height: 8.h),
                            // CustomTextField(
                            //   hintText: 'Enter password',
                            //   initialValue: viewModel.password,
                            //   isPassword: true,
                            //   onChanged: viewModel.setPassword,
                            // ),

                            // SizedBox(height: 24.h),

                            // // Confirm Password field
                            // Text(
                            //   'Confirm Password',
                            //   style: TextStyle(
                            //     fontSize: 16.sp,
                            //     fontWeight: FontWeight.w600,
                            //     color: AppColors.black,
                            //   ),
                            // ),
                            // SizedBox(height: 8.h),
                            // CustomTextField(
                            //   hintText: 'Confirm password',
                            //   initialValue: viewModel.confirmPassword,
                            //   isPassword: true,
                            //   onChanged: viewModel.setConfirmPassword,
                            // ),

                            SizedBox(height: 20.h),

                            // Preferred Language
                            // Text(
                            //   'Preferred Language',
                            //   style: TextStyle(
                            //     fontSize: 16.sp,
                            //     fontWeight: FontWeight.w600,
                            //     color: AppColors.black,
                            //   ),
                            // ),
                            // SizedBox(height: 8.h),
                            // GestureDetector(
                            //   onTap: () =>
                            //       _showLanguageBottomSheet(context, viewModel),
                            //   child: Container(
                            //     width: double.infinity,
                            //     height: 50.h,
                            //     decoration: BoxDecoration(
                            //       border: Border.all(
                            //         color: AppColors.greyLight,
                            //       ),
                            //       borderRadius: BorderRadius.circular(30.r),
                            //     ),
                            //     child: Padding(
                            //       padding: EdgeInsets.symmetric(
                            //         horizontal: 16.w,
                            //       ),
                            //       child: Row(
                            //         mainAxisAlignment:
                            //             MainAxisAlignment.spaceBetween,
                            //         children: [
                            //           Text(
                            //             viewModel.selectedLanguage,
                            //             style: TextStyle(
                            //               fontSize: 14.sp,
                            //               color:
                            //                   viewModel.selectedLanguage ==
                            //                       'Select language'
                            //                   ? AppColors.grey
                            //                   : AppColors.black,
                            //             ),
                            //           ),
                            //           Icon(
                            //             Icons.keyboard_arrow_down,
                            //             color: AppColors.grey,
                            //             size: 20.sp,
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),

                            // SizedBox(height: 32.h),

                            // Notifications section
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Morning Prompt toggle
                            _buildNotificationToggle(
                              '🌅',
                              'Morning Prompt',
                              viewModel.morningPrompt,
                              viewModel.setMorningPrompt,
                            ),

                            SizedBox(height: 12.h),

                            // Evening Reflection toggle
                            _buildNotificationToggle(
                              '🌙',
                              'Evening Reflection',
                              viewModel.eveningReflection,
                              viewModel.setEveningReflection,
                            ),

                            SizedBox(height: 12.h),

                            // Challenge toggle
                            _buildNotificationToggle(
                              '🎯',
                              'Challenge',
                              viewModel.challenge,
                              viewModel.setChallenge,
                            ),

                            // Show error message if any
                            if (viewModel.errorMessage != null) ...[
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],

                            // Extra space at bottom for scroll above keyboard
                            SizedBox(height: keyboardHeight > 0 ? keyboardHeight + 20.h : 100.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Clean bottom navigation section
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24.w, // left - slightly more than content
                    20.h, // top - breathing room
                    24.w, // right - symmetric
                    _calculateBottomPadding(context), // dynamic bottom
                  ),
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: () {
                      if (viewModel.canProceedFromPageTwo()) {
                        onContinue();
                      } else {
                        // Trigger validation
                        viewModel.authenticateAndComplete(context);
                      }
                    },
                    width: double.infinity,
                    height: 52.h,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    String emoji,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 20.sp)),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
        _CustomSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  /// Calculates professional bottom padding based on device characteristics
  double _calculateBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Base padding following iOS Human Interface Guidelines and Material Design
    double basePadding = 20.h;
    
    // Add safe area padding for devices with home indicator (iPhone X and later)
    if (bottomPadding > 0) {
      basePadding += bottomPadding.clamp(0.0, 34.0); // Max 34pt for home indicator
    } else {
      // For devices without home indicator, add standard spacing
      basePadding += 16.h;
    }
    
    // Adjust for different screen sizes
    if (screenHeight < 600) {
      // Small screens (iPhone SE, small Android phones)
      basePadding *= 0.8;
    } else if (screenHeight > 900) {
      // Large screens (iPhone Pro Max, large Android phones, tablets)
      basePadding *= 1.2;
    }
    
    // Ensure minimum spacing for accessibility
    return basePadding.clamp(24.h, 60.h);
  }

}

class _CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({required this.value, required this.onChanged});

  @override
  State<_CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<_CustomSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _value = !_value;
        });
        widget.onChanged(_value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50.w,
        height: 28.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: _value ? AppColors.primary(context) : AppColors.greyLight,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24.w,
            height: 24.h,
            margin: EdgeInsets.all(2.w),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

