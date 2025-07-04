import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

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
        backgroundColor: AppColors.accentDark,
        body: SafeArea(
          child: Column(
            children: [
              // Header
             Align(
              alignment: Alignment.centerLeft,
              child:  Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'Ledger',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
             ),

              // Tab bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                height: 45.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
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
                                ? AppColors.primary
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
                                    ? Colors.white
                                    : Colors.black,
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
