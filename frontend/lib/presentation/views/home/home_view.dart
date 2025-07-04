import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/constants/app_colors.dart';

import 'home_viewmodel.dart';
import 'widgets/greeting_header.dart';
import 'widgets/verse_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/challenge_card.dart';
import 'widgets/recent_activities.dart';
import '../../shared/widgets/custom_bottom_nav.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: AppColors.accentDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingHeader(
                      userName: viewModel.userName,
                      subtitle: viewModel.todaySubtitle,
                      fireCount: viewModel.fireCount,
                    ),

                    VerseCard(
                      verse: viewModel.todaysVerse,
                      onBookmarkTap: viewModel.toggleBookmark,
                    ),

                    const QuickActions(),

                    ChallengeCard(challenge: viewModel.todaysChallenge),

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
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}
