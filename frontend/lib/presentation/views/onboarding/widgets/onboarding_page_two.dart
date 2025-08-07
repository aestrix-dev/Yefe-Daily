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
                              color: Colors.black.withOpacity(0.1),
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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
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
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            CustomTextField(
                              hintText: 'Enter password',
                              initialValue: viewModel.password,
                              isPassword: true,
                              onChanged: viewModel.setPassword,
                            ),

                            SizedBox(height: 24.h),

                            // Confirm Password field
                            Text(
                              'Confirm Password',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            CustomTextField(
                              hintText: 'Confirm password',
                              initialValue: viewModel.confirmPassword,
                              isPassword: true,
                              onChanged: viewModel.setConfirmPassword,
                            ),

                            SizedBox(height: 24.h),

                            // Preferred Language
                            Text(
                              'Preferred Language',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () =>
                                  _showLanguageBottomSheet(context, viewModel),
                              child: Container(
                                width: double.infinity,
                                height: 50.h,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.greyLight,
                                  ),
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        viewModel.selectedLanguage,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color:
                                              viewModel.selectedLanguage ==
                                                  'Select language'
                                              ? AppColors.grey
                                              : AppColors.black,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.grey,
                                        size: 20.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),

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
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
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

                            // Extra space at bottom for scroll
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 6.h),
                // Button section - fixed at bottom
                Padding(
                  padding: EdgeInsets.all(16.w),
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
                    height: 50.h,
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

  void _showLanguageBottomSheet(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.accentDark(context),
      isScrollControlled: true,
      builder: (context) => LanguageBottomSheet(
        selectedLanguage: viewModel.selectedLanguage,
        onLanguageSelected: viewModel.setSelectedLanguage,
      ),
    );
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

class LanguageBottomSheet extends StatefulWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageSelected;

  const LanguageBottomSheet({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<LanguageBottomSheet> {
  final List<String> languages = ['English', 'French', 'Spanish', 'Portuguese'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentDark(context),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),

          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 20.h),

          Text(
            'Select Language',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),

          SizedBox(height: 20.h),

          ...languages.map((language) => _buildLanguageOption(language)),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = widget.selectedLanguage == language;
    final isLast = language == languages.last;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            widget.onLanguageSelected(language);
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary(context)
                        : AppColors.black,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: AppColors.primary(context),
                    size: 20.sp,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1.h,
            thickness: 0.5,
            color: AppColors.greyLight,
            indent: 24.w,
            endIndent: 24.w,
          ),
      ],
    );
  }
}
