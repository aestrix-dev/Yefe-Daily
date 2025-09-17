import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/data/models/challenge_stats_model.dart';
import '../../../../core/constants/app_colors.dart';

class ProgressStats extends StatefulWidget {
  final ChallengeStatsModel stats;

  const ProgressStats({super.key, required this.stats});

  @override
  State<ProgressStats> createState() => _ProgressStatsState();
}

class _ProgressStatsState extends State<ProgressStats>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.stats.progressPercentage).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
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
              color: AppColors.textPrimary(context),
            ),
          ),

          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Progress',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Text(
                '${widget.stats.sevenDaysProgress}/7 Days',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),

          _buildProgressBar(context),

          SizedBox(height: 20.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context: context,
                iconPath: 'assets/icons/badge.png',
                count: widget.stats.numberOfBadges,
                label: 'Badges',
              ),
              _buildStatItem(
                context: context,
                iconPath: 'assets/icons/challenge.png',
                count: widget.stats.totalChallenges,
                label: 'Challenges',
              ),
              _buildStatItem(
                context: context,
                iconPath: 'assets/icons/streak.png',
                count: widget.stats.longestStreak,
                label: 'Top Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    // Progress is based on 7-day progress, animation handled by _progressAnimation

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
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 4.h),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Text(
              '${(_progressAnimation.value * 100).toInt()}% Complete',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
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
              color: AppColors.primary(context),
            );
          },
        ),
        SizedBox(height: 8.h),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
