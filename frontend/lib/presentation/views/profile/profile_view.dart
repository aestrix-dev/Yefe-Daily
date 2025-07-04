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
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),

                // Profile Header (Avatar, Name, Upgrade button)
                ProfileHeader(
                  userName: viewModel.userName,
                  userPlan: viewModel.userPlan,
                  avatarUrl: viewModel.avatarUrl,
                  onUpgrade: () => _showUpgradePopup(context, viewModel),
                ),

                SizedBox(height: 16.h),

                // Upgrade Card (conditional) - REMOVED since we're using popup now

                // Progress Stats (similar to challenges screen)
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 20.w,
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressItem(
                            icon: Icons.local_fire_department,
                            iconColor: Colors.orange,
                            value: '7 day',
                            label: 'streak',
                          ),
                          _buildProgressItem(
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                            value: '12',
                            label: 'Challenges',
                          ),
                          _buildProgressItem(
                            icon: Icons.emoji_events,
                            iconColor: Colors.amber,
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
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32.sp, color: iconColor),
        SizedBox(height: 8.h),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
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
