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

          _buildProgressBar(),

          SizedBox(height: 20.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                iconPath:
                    'assets/icons/badge.png', 
                count: stats.totalBadges,
                label: 'Badges',
              ),
              _buildStatItem(
                iconPath:
                    'assets/icons/challenge.png',
                count: stats.totalChallenges,
                label: 'Challenges',
              ),
              _buildStatItem(
                iconPath:
                    'assets/icons/streak.png', 
                count: stats.topStreak,
                label: 'Top Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    
    double progress = stats.topStreak > 0
        ? stats.currentStreak / stats.topStreak
        : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          height: 8.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String iconPath,
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        
        Image.asset(
          iconPath,
          width: 29.w,
          height: 29.h,
         
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.emoji_events, 
              size: 16.sp,
              color: AppColors.primary,
            );
          },
        ),
        SizedBox(height: 8.h),
      
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
