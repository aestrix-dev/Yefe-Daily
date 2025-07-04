import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/constants/app_routes.dart';
import 'package:yefa/data/services/storage_service.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';

class OnboardingPageThree extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingPageThree({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<OnboardingPageThree> createState() => _OnboardingPageThreeState();
}

class _OnboardingPageThreeState extends State<OnboardingPageThree> {
  TimeOfDay? morningTime;
  TimeOfDay? eveningTime;
  bool _isNavigating = false;

  // Check if both times are selected
  bool get isFormValid => morningTime != null && eveningTime != null;

  @override
  void initState() {
    super.initState();
    // Set default times
    morningTime = const TimeOfDay(hour: 6, minute: 0); // 6:00 AM
    eveningTime = const TimeOfDay(hour: 21, minute: 0); // 9:00 PM
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Changed from Scaffold to Stack for background
      children: [
        // Background image that fills the entire screen
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Original content on top
        Scaffold(
          backgroundColor: Colors.transparent, // Make scaffold transparent
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 58.h),
                // Back button section
                Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.accentDark,
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

                // Card section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.accentDark,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              time: morningTime,
                              onTap: () => _selectTime(context, true),
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
                              time: eveningTime,
                              onTap: () => _selectTime(context, false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Set Reminder button
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: CustomButton(
                    text: _isNavigating ? 'Setting...' : 'Set Reminder',
                    onPressed: _isNavigating ? () {} : _handleSetReminder,
                    width: double.infinity,
                    height: 56.h,
                    backgroundColor: AppColors.accentLight,
                  ),
                ),
                SizedBox(height: 120.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
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
          color: AppColors.backgroundLight,
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

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMorning
          ? (morningTime ?? const TimeOfDay(hour: 6, minute: 0))
          : (eveningTime ?? const TimeOfDay(hour: 21, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.white,
              hourMinuteTextColor: AppColors.black,
              hourMinuteColor: AppColors.primaryLight,
              dayPeriodTextColor: AppColors.black,
              dayPeriodColor: AppColors.primaryLight,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.backgroundLight,
              dialTextColor: AppColors.black,
              entryModeIconColor: AppColors.primary,
              helpTextStyle: TextStyle(color: AppColors.black, fontSize: 16.sp),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMorning) {
          morningTime = picked;
        } else {
          eveningTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;

    return '$displayHour:$minute $period';
  }

  void _handleSetReminder() async {
    if (isFormValid && !_isNavigating) {
      setState(() {
        _isNavigating = true;
      });

      // Print the reminder times
      print('Morning reminder set for: ${_formatTime(morningTime!)}');
      print('Evening reminder set for: ${_formatTime(eveningTime!)}');

      // Save to storage directly here
      final _storageService = locator<StorageService>();
      await _storageService.setBool('hasSeenOnboarding', true);
      await _storageService.setBool('isLoggedIn', true);

      print('OnboardingPageThree: Storage values set, navigating to home');

      // Navigate directly using the widget's context
      if (mounted) {
        context.pushReplacement(AppRoutes.home);
      }
    }
  }
}
