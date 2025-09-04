import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import 'challenges_viewmodel.dart';
import 'widgets/puzzle_section.dart';
import 'widgets/challenge_card.dart';
import 'widgets/progress_stats.dart';

class ChallengesView extends StackedView<ChallengesViewModel> {
  const ChallengesView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ChallengesViewModel viewModel,
    Widget? child,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.contextAlreadySet != true) {
        viewModel.setContext(context);
      }
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
              // Header
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Text(
                    'Puzzles & Challenges',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ),

              // Tab bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.accentLight(context),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => viewModel.selectTab(0),
                        child: Container(
                          margin: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: viewModel.isActiveTab
                                ? AppColors.primary(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          child: Center(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: viewModel.isActiveTab
                                    ? Colors.white
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => viewModel.selectTab(1),
                        child: Container(
                          margin: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: viewModel.isCompletedTab
                                ? AppColors.primary(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          child: Center(
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: viewModel.isCompletedTab
                                    ? Colors.white
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 9.h),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.isActiveTab) ...[
                        // Daily Puzzle - now using new puzzle system
                        PuzzleSection(
                          puzzleState: viewModel.puzzleState,
                          isSubmitting: viewModel.isSubmittingAnswer,
                          onAnswerSelected: viewModel.selectPuzzleAnswer,
                          onSubmit: viewModel.submitPuzzleAnswer,
                        ),

                        SizedBox(height: 20.h),

                        // Active Challenges
                        ...viewModel.activeChallenges.map(
                          (challenge) => ChallengeCard(
                            challenge: challenge,
                            onMarkComplete: () async => await viewModel
                                .markChallengeAsComplete(challenge.id),
                            isEnabled: viewModel.shouldEnableMarkAsDone(challenge),
                            isBeingMarked: viewModel.isChallengeBeingMarked(challenge.id),
                          ),
                        ),
                      ] else ...[
                        // Progress Stats
                        ProgressStats(stats: viewModel.progressStats),

                        SizedBox(height: 16.h),

                        // Previous Challenges section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            'Previous Challenges',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Completed Challenges
                        if (viewModel.completedChallenges.isNotEmpty) ...[
                          ...viewModel.completedChallenges.map(
                            (challenge) => ChallengeCard(
                              challenge: challenge,
                              isCompleted: true,
                            ),
                          ),
                        ] else ...[
                          // Empty state for completed challenges
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight(context),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 48.sp,
                                    color: AppColors.primary(context),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No completed challenges yet',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Complete your first challenge to see it here!',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],

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
    );
  }

  @override
  ChallengesViewModel viewModelBuilder(BuildContext context) =>
      ChallengesViewModel();

  @override
  void onViewModelReady(ChallengesViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}
