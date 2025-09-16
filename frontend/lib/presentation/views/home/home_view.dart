import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/constants/app_colors.dart';
import 'package:yefa/core/constants/app_routes.dart';

import 'home_viewmodel.dart';
import 'widgets/greeting_header.dart';
import 'widgets/verse_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/challenge_card.dart';
import 'widgets/recent_activities.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import '../../shared/widgets/back_button_handler.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BackButtonHandler(
      currentRoute: AppRoutes.home,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Greeting
                      GreetingHeader(
                        userName: viewModel.userName,
                        subtitle: viewModel.todaySubtitle,
                        fireCount: viewModel.fireCount,
                      ),

                      /// Verse Card
                      VerseCard(
                        verse: viewModel.todaysVerse,
                        onBookmarkTap: viewModel.toggleBookmark,
                      ),

                      /// Quick Actions
                      const QuickActions(),

                      /// Challenge Card or fallback
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: viewModel.todaysChallenge != null
                            ? ChallengeCard(
                                challenge: viewModel.todaysChallenge!,
                              )
                            : _buildNoChallengeCard(context),
                      ),

                      /// Recent Activities
                      RecentActivities(activities: viewModel.recentActivities),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
      ),
    );
  }

  /// No Challenge Available Fallback UI
  Widget _buildNoChallengeCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Challenge",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'No challenge available for today. Please check back tomorrow!',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.initialize();
  }
}
