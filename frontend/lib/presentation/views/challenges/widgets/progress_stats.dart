import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/puzzle_model.dart';

class ProgressStats extends StatelessWidget {
  final ProgressStatsModel stats;

  const ProgressStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          SizedBox(height: 8.h),

          // Current streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Streak',
                style: TextStyle(fontSize: 14.sp, color: Colors.black),
              ),
              Text(
                '${stats.currentStreak} Days',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                icon: Icons.emoji_events,
                iconColor: Colors.orange,
                count: stats.totalBadges,
                label: 'Badges',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                count: stats.totalChallenges,
                label: 'Challenges',
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                icon: Icons.trending_up,
                iconColor: Colors.blue,
                count: stats.topStreak,
                label: 'Top 5',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24.sp, color: iconColor),
            SizedBox(height: 8.h),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
