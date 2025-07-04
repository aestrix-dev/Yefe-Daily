import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: AppStrings.home,
            route: AppRoutes.home,
            isActive: currentRoute == AppRoutes.home,
          ),
          _buildNavItem(
            context,
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: AppStrings.journal,
            route: AppRoutes.journal,
            isActive: currentRoute == AppRoutes.journal,
          ),
          _buildNavItem(
            context,
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events,
            label: AppStrings.challenges,
            route: AppRoutes.challenges,
            isActive: currentRoute == AppRoutes.challenges,
          ),
          _buildNavItem(
            context,
            icon: Icons.headphones_outlined,
            activeIcon: Icons.headphones,
            label: AppStrings.audio,
            route: '/audio',
            isActive: currentRoute == '/audio',
          ),
          _buildNavItem(
            context,
            icon: Icons.more_horiz,
            activeIcon: Icons.more_horiz,
            label: AppStrings.more,
            route: '/more',
            isActive: currentRoute == '/more',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? Colors.blue : Colors.grey,
            size: 24.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
