import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/data/models/challenge_model.dart';
import '../../../../core/constants/app_colors.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onMarkComplete;
  final bool isCompleted;
  final bool isEnabled;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onMarkComplete,
    this.isCompleted = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and points
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              if (challenge.type == ChallengeType.manhood &&
                  !challenge.isCompleted) ...[
                Icon(
                  Icons.local_fire_department,
                  size: 16.sp,
                  color: Colors.orange,
                ),
                SizedBox(width: 4.w),
                Text(
                  '+${challenge.points} points',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 8.h),

          // Description
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
          ),

          SizedBox(height: 16.h),

          // Action button or completed status
          if (isCompleted)
            Row(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 14.sp, color: Colors.white),
                ),
                SizedBox(width: 8.w),
                Text(
                  challenge.completedDate != null
                      ? _formatCompletedDate(challenge.completedDate!)
                      : 'Completed',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: challenge.isCompleted
                    ? null
                    : (isEnabled ? onMarkComplete : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: challenge.isCompleted
                      ? AppColors.primary(context)
                      : (isEnabled ? AppColors.primary(context) : AppColors.accentDark(context)),
                  disabledBackgroundColor: challenge.isCompleted
                      ? AppColors.primary(context)
                      : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (challenge.isCompleted) ...[
                      Icon(Icons.check, size: 18.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      challenge.isCompleted
                          ? 'Completed'
                          : (isEnabled
                                ? 'Mark as done'
                                : 'Complete puzzle first'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCompletedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Completed today';
    } else if (difference.inDays == 1) {
      return 'Completed yesterday';
    } else {
      return 'Completed ${date.day}/${date.month}';
    }
  }
}
