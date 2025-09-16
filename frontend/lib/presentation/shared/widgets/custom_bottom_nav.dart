// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:yefa/core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final adjustedBottomPadding = bottomPadding > 0 ? (bottomPadding * 0.6).toDouble() : 0.0;

    return Container(
      height: 70.h + adjustedBottomPadding,
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          _buildNavItem(
            context,
            iconPath: 'assets/icons/home.png',
            label: 'Home',
            route: '/home',
            isActive: currentRoute == '/home',
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/icons/ledger.png',
            label: 'Ledger',
            route: '/journal',
            isActive: currentRoute == '/journal',
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/icons/challenges.png',
            label: 'Challenges',
            route: '/challenges',
            isActive: currentRoute == '/challenges',
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/icons/audio.png',
            label: 'Audio',
            route: '/audio',
            isActive: currentRoute == '/audio',
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/icons/profile.png',
            label: 'Profile',
            route: '/profile',
            isActive: currentRoute == '/profile',
          ),
              ],
              ),
            ),
          ),
          SizedBox(height: adjustedBottomPadding),
        ],
      ),
    );
  }

Widget _buildNavItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required String route,
    required bool isActive,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define colors based on theme and active state
    final Color activeIconColor = isDarkMode 
        ? AppColors.primaryLight(context) 
        : AppColors.primary(context);
    
    final Color inactiveIconColor = isDarkMode 
        ? AppColors.textSecondary(context) 
        : Colors.grey[600]!;
    
    final Color inactiveTextColor = isDarkMode 
        ? AppColors.textSecondary(context) 
        : Colors.grey[600]!;
    
    final double iconOpacity = isActive ? 1.0 : (isDarkMode ? 0.8 : 0.6);
    
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: iconOpacity,
            child: Image.asset(
              iconPath,
              width: 22.w,
              height: 22.h,
              color: isActive
                  ? activeIconColor
                  : inactiveIconColor,
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isActive ? AppColors.textPrimary(context) : inactiveTextColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
