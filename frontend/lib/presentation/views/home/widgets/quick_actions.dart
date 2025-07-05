import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(
            context,
            iconPath: 'assets/icons/journal.png',
            label: 'Write Journal',
            onTap: () => context.push('/journal'),
          ),
          _buildActionItem(
            context,
            iconPath: 'assets/icons/puzzle.png',
            label: 'Play Puzzles',
            onTap: () => context.push('/challenges'),
          ),
          _buildActionItem(
            context,
            iconPath: 'assets/icons/devotional.png',
            label: 'Devotionals',
            onTap: () => context.push('/audio'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w, 
        height: 75.h, 
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom icon
            Image.asset(iconPath, width: 30.w, height: 30.h),
            SizedBox(height: 6.h),
            // Text below icon
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
