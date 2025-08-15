import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/core/constants/app_colors.dart';
import 'package:yefa/data/models/journal_model.dart';
import 'package:intl/intl.dart';

class RecentActivities extends StatelessWidget {
  final List<JournalModel> activities;

  const RecentActivities({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        if (activities.isEmpty)
          _buildEmptyState(context)
        else
          ...activities.map(
            (activity) => _buildActivityItem(context, activity),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 32.sp,
              color: AppColors.textSecondary(context),
            ),
            SizedBox(height: 8.h),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your spiritual activities will appear here',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, JournalModel activity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with title and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatActivityTitle(activity),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Text(
                _formatTime(activity.createdAt),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Subtitle/description
          Text(
            activity.content,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatActivityTitle(JournalModel activity) {
    // Capitalize the type (e.g., "morning" -> "Morning")
    String capitalizedType = activity.type.isNotEmpty
        ? activity.type[0].toUpperCase() + activity.type.substring(1)
        : '';

    // Get first tag if available
    String firstTag = '';
    if (activity.tags.isNotEmpty) {
      firstTag = ' • ${activity.tags[0]}';
    }

    return '$capitalizedType Reflection$firstTag';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "Aug 15"
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
