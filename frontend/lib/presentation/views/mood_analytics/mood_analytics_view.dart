import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/loading_widget.dart';
import 'mood_analytics_viewmodel.dart';
import 'widgets/simple_sleep_chart.dart';
import 'widgets/mood_stats_card.dart';

class MoodAnalyticsView extends StackedView<MoodAnalyticsViewModel> {
  const MoodAnalyticsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MoodAnalyticsViewModel viewModel,
    Widget? child,
  ) {
    // Set context for navigation
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
                    
                    Text(
                      'Sleep Analytics',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: viewModel.isBusy
                    ? const LoadingWidget()
                    : viewModel.weeklyMoodData == null
                        ? Center(
                            child: Text(
                              'No mood data available',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: 8.h),
                                
                                // Animated Chart
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: SimpleSleepChart(
                                    sleepData: viewModel.sleepGraphResponse,
                                    isAnimated: viewModel.isAnimated,
                                  ),
                                ),
                                
                                SizedBox(height: 24.h),
                                
                                // Stats Card
                                MoodStatsCard(
                                  weeklyMoodData: viewModel.weeklyMoodData!,
                                  insight: viewModel.getWeeklyInsight(),
                                  viewModel: viewModel,
                                ),
                                
                                SizedBox(height: 24.h),
                              ],
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
  MoodAnalyticsViewModel viewModelBuilder(BuildContext context) => 
      MoodAnalyticsViewModel();

  @override
  void onViewModelReady(MoodAnalyticsViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }

}