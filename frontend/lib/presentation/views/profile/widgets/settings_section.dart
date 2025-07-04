import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsSection extends StatelessWidget {
  final bool isDarkMode;
  final bool isNotificationsEnabled;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationsToggle;
  final VoidCallback onVerseLanguageTap;

  const SettingsSection({
    super.key,
    required this.isDarkMode,
    required this.isNotificationsEnabled,
    required this.onThemeToggle,
    required this.onNotificationsToggle,
    required this.onVerseLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Settings container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              // Notifications
              _buildSettingItem(
                icon: Icons.notifications,
                title: 'Notifications',
                trailing: Switch(
                  value: isNotificationsEnabled,
                  onChanged: (_) => onNotificationsToggle(),
                  activeColor: AppColors.primary,
                ),
                showBottomBorder: true,
              ),

              // Verse Language
              _buildSettingItem(
                icon: Icons.translate,
                title: 'Verse Language',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                onTap: onVerseLanguageTap,
                showBottomBorder: true,
              ),

              // Dark Mode
              _buildSettingItem(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (_) => onThemeToggle(),
                  activeColor: AppColors.primary,
                ),
                showBottomBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    bool showBottomBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: Colors.grey[700]),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
