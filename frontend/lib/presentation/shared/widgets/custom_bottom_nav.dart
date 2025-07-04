import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:yefa/core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
    );
  }

Widget _buildNavItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),

    
          Opacity(
            opacity: isActive
                ? 1.0
                : 0.4, 
            child: Image.asset(
              iconPath,
              width: 24.w,
              height: 24.h,
              color: isActive
                  ? AppColors.primary
                  : null, 
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: isActive ? Colors.black : Colors.grey[400],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
