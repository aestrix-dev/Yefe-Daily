import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import 'profile_viewmodel.dart';
import 'widgets/upgrade_popup.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/community_section.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ProfileViewModel viewModel,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),

               
                ProfileHeader(
                  userName: viewModel.userName,
                  userPlan: viewModel.userPlan,
                  avatarUrl: viewModel.avatarUrl,
                  onUpgrade: () => _showUpgradePopup(context, viewModel),
                ),

                SizedBox(height: 16.h),

              
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressItem(
                            iconPath: 'assets/icons/fire.png',
                            value: '7/365 day',
                            label: 'streak',
                          ),
                          _buildProgressItem(
                            iconPath: 'assets/icons/challenge.png',
                            value: '12',
                            label: 'Challenges',
                          ),
                          _buildProgressItem(
                            iconPath: 'assets/icons/badge.png',
                            value: '5',
                            label: 'Badges',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Settings Section
                SettingsSection(
                  isDarkMode: viewModel.isDarkMode,
                  isNotificationsEnabled: viewModel.isNotificationsEnabled,
                  onThemeToggle: viewModel.toggleTheme,
                  onNotificationsToggle: viewModel.toggleNotifications,
                  onVerseLanguageTap: viewModel.navigateToVerseLanguage,
                ),

                SizedBox(height: 20.h),

                // Community Section
                CommunitySection(
                  onYefaManCaveTap: viewModel.navigateToYefaManCave,
                  onTowelTalkTap: viewModel.navigateToTowelTalk,
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }

  void _showUpgradePopup(BuildContext context, ProfileViewModel viewModel) {
    if (!viewModel.isPremium) {
      UpgradePopup.show(context, onUpgrade: viewModel.upgradeToPremium);
    }
  }

  Widget _buildProgressItem({
    required String iconPath,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Image.asset(
          iconPath,
          width: 32.sp,
          height: 32.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) => ProfileViewModel();

  @override
  void onViewModelReady(ProfileViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}
