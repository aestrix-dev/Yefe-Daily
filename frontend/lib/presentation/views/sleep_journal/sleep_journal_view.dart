import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/loading_widget.dart';
import 'sleep_journal_viewmodel.dart';
import 'widgets/sleep_form_card.dart';
import 'widgets/sleep_duration_display.dart';
import 'widgets/quick_preset_buttons.dart';

class SleepJournalView extends StackedView<SleepJournalViewModel> {
  const SleepJournalView({super.key});

  @override
  Widget builder(
    BuildContext context,
    SleepJournalViewModel viewModel,
    Widget? child,
  ) {
    // Set context for date/time pickers and navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.setContext(context);
    });

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.accentDark(context),
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: viewModel.navigateBack,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight(context),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18.sp,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sleep Journal',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            'Track your sleep patterns',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Premium badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withAlpha(25),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary(context).withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 12.sp,
                            color: AppColors.primary(context),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: viewModel.isBusy
                    ? const LoadingWidget()
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            children: [
                              // Sleep Duration Display Card
                              SleepDurationDisplay(
                                duration: viewModel.sleepDuration,
                                durationFormatted: viewModel.sleepDurationFormatted,
                                isValid: viewModel.isFormValid,
                              ),
                              
                              SizedBox(height: 20.h),

                              // Quick Preset Buttons
                              QuickPresetButtons(
                                onPreset7Hours: viewModel.setPreset7Hours,
                                onPreset8Hours: viewModel.setPreset8Hours,
                                onPreset9Hours: viewModel.setPreset9Hours,
                                activePreset: viewModel.activePreset,
                              ),
                              
                              SizedBox(height: 20.h),

                              // Sleep Form Card
                              SleepFormCard(
                                sleptDate: viewModel.sleptDateFormatted,
                                sleptTime: viewModel.sleptTimeFormatted,
                                wokeUpDate: viewModel.wokeUpDateFormatted,
                                wokeUpTime: viewModel.wokeUpTimeFormatted,
                                onSleptDateTap: viewModel.selectSleptDate,
                                onSleptTimeTap: viewModel.selectSleptTime,
                                onWokeUpDateTap: viewModel.selectWokeUpDate,
                                onWokeUpTimeTap: viewModel.selectWokeUpTime,
                              ),

                              SizedBox(height: 20.h),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: viewModel.isFormValid && !viewModel.isSubmitting
                                      ? viewModel.submitSleepJournal
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary(context),
                                    disabledBackgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.white,
                                    elevation: viewModel.isFormValid ? 2 : 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: viewModel.isSubmitting
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16.w,
                                              height: 16.h,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Text(
                                              'Saving Sleep Journal...',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.bedtime,
                                              size: 18.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Save Sleep Journal',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // View Analytics Button
                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: OutlinedButton(
                                  onPressed: viewModel.navigateToAnalytics,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primary(context),
                                      width: 1.5,
                                    ),
                                    foregroundColor: AppColors.primary(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'View Sleep Analytics',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  SleepJournalViewModel viewModelBuilder(BuildContext context) => 
      SleepJournalViewModel();

  @override
  void onViewModelReady(SleepJournalViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}