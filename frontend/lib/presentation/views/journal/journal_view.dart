import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import 'journal_viewmodel.dart';
import 'widgets/upgrade_card.dart';
import 'widgets/journal_form.dart';

class JournalView extends StackedView<JournalViewModel> {
  const JournalView({super.key});

  @override
  Widget builder(
    BuildContext context,
    JournalViewModel viewModel,
    Widget? child,
  ) {
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
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ledger',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push('/history');
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight(context),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Image.asset(
                          'assets/icons/history.png',
                          width: 20.w,
                          height: 20.h,
                          color: AppColors.textPrimary(context),
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.history,
                              size: 20.sp,
                              color: AppColors.textPrimary(context),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                height: 45.h,
                decoration: BoxDecoration(
                  color: AppColors.accentLight(context),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Row(
                  children: List.generate(
                    viewModel.tabTitles.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () => viewModel.selectTab(index),
                        child: Container(
                          margin: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: viewModel.selectedTabIndex == index
                                ? AppColors.primary(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          child: Center(
                            child: Text(
                              viewModel.tabTitles[index],
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: viewModel.selectedTabIndex == index
                                    ? Colors.grey[300]
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 14.h),
              // Content
              Center(
                child: viewModel.shouldShowUpgradeCard
                    ? UpgradeCard(onUpgrade: viewModel.handleUpgrade)
                    : JournalForm(
                        content: viewModel.journalContent,
                        selectedTags: viewModel.selectedTags,
                        availableTags: viewModel.availableTags,
                        onContentChanged: viewModel.updateJournalContent,
                        onTagToggle: viewModel.toggleTag,
                        onSave: viewModel.saveJournalEntry,
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
  JournalViewModel viewModelBuilder(BuildContext context) => JournalViewModel();
}
