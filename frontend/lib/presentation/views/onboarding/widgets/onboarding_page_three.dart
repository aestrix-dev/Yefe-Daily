import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../onboarding_viewmodel.dart';

class OnboardingPageThree extends ViewModelWidget<OnboardingViewModel> {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingPageThree({
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 58.h),
                          // Back button section
                          Padding(
                            padding: EdgeInsets.all(15.w),
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

                          // Card section - now flexible
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
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
                                child: Padding(
                                  padding: EdgeInsets.all(15.w),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        'Reminders Setup',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.black,
                                          height: 1.2,
                                        ),
                                      ),

                                      SizedBox(height: 40.h),

                                      // Morning Reminder
                                      Text(
                                        'Morning Reminder',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black,
                                        ),
                                      ),

                                      SizedBox(height: 12.h),

                                      _buildTimeSelector(
                                        context: context,
                                        time: _parseTimeString(
                                          viewModel.morningReminder,
                                        ),
                                        onTap: () => _selectTime(
                                          context,
                                          viewModel,
                                          true,
                                        ),
                                      ),

                                      SizedBox(height: 32.h),

                                      // Evening Reminder
                                      Text(
                                        'Evening Reminder',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black,
                                        ),
                                      ),

                                      SizedBox(height: 12.h),

                                      _buildTimeSelector(
                                        context: context,
                                        time: _parseTimeString(
                                          viewModel.eveningReminder,
                                        ),
                                        onTap: () => _selectTime(
                                          context,
                                          viewModel,
                                          false,
                                        ),
                                      ),

                                      // Animated error message container
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        height: viewModel.errorMessage != null
                                            ? null
                                            : 0,
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          opacity:
                                              viewModel.errorMessage != null
                                              ? 1.0
                                              : 0.0,
                                          child: viewModel.errorMessage != null
                                              ? Container(
                                                  margin: EdgeInsets.only(
                                                    top: 24.h,
                                                  ),
                                                  padding: EdgeInsets.all(12.w),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.red
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 20.sp,
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      Expanded(
                                                        child: Text(
                                                          viewModel
                                                              .errorMessage!,
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 14.sp,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),

                                      // Add some bottom padding to the card content
                                      SizedBox(height: 20.h),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Spacer to push button to bottom
                          // const Spacer(),

                          // Set Reminder button - fixed at bottom
                          Padding(
                            padding: EdgeInsets.all(20.w),
                            child: CustomButton(
                              text: viewModel.isAuthenticating
                                  ? 'Authenticating...'
                                  : 'Set Reminder',
                              onPressed: viewModel.isAuthenticating
                                  ? null
                                  : () => viewModel.authenticateAndComplete(
                                      context,
                                    ),
                              width: double.infinity,
                              height: 56.h,
                              backgroundColor: AppColors.accentLight(context),
                            ),
                          ),

                          // Bottom safe area
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyLight),
          borderRadius: BorderRadius.circular(40.r),
          color: AppColors.backgroundLight(context),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time != null ? _formatTime(time) : 'Select time',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: time != null ? AppColors.black : AppColors.grey,
                ),
              ),
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.access_time,
                  size: 20.sp,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    OnboardingViewModel viewModel,
    bool isMorning,
  ) async {
    final currentTime = isMorning
        ? _parseTimeString(viewModel.morningReminder)
        : _parseTimeString(viewModel.eveningReminder);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          currentTime ??
          (isMorning
              ? const TimeOfDay(hour: 6, minute: 0)
              : const TimeOfDay(hour: 21, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.white,
              hourMinuteTextColor: AppColors.black,
              hourMinuteColor: AppColors.primaryLight(context),
              dayPeriodTextColor: AppColors.black,
              dayPeriodColor: AppColors.primaryLight(context),
              dialHandColor: AppColors.primary(context),
              dialBackgroundColor: AppColors.backgroundLight(context),
              dialTextColor: AppColors.black,
              entryModeIconColor: AppColors.primary(context),
              helpTextStyle: TextStyle(color: AppColors.black, fontSize: 16.sp),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary(context),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = _formatTimeToString(picked);
      if (isMorning) {
        viewModel.setMorningReminder(timeString);
      } else {
        viewModel.setEveningReminder(timeString);
      }
    }
  }

  // Display format (what user sees)
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;

    return '$displayHour:$minute $period';
  }

  // Storage format (what gets saved) - now in 12-hour format with AM/PM
  String _formatTimeToString(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;

    return '$displayHour:$minute $period';
  }

  // Parse 12-hour format string back to TimeOfDay
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      if (timeString.isEmpty) return null;

      // Handle both 12-hour and 24-hour formats for backward compatibility
      if (timeString.contains('AM') || timeString.contains('PM')) {
        // 12-hour format: "6:30 AM" or "9:45 PM"
        final parts = timeString.split(' ');
        if (parts.length != 2) return null;

        final timePart = parts[0];
        final period = parts[1];

        final timeParts = timePart.split(':');
        if (timeParts.length != 2) return null;

        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Convert to 24-hour format for TimeOfDay
        if (period == 'AM') {
          if (hour == 12) hour = 0; // 12 AM is 0 hours
        } else {
          // PM
          if (hour != 12) hour += 12; // PM times except 12 PM
        }

        return TimeOfDay(hour: hour, minute: minute);
      } else {
        // 24-hour format: "06:30" (for backward compatibility)
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {

    }
    return null;
  }
}
