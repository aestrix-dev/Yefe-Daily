import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/core/constants/app_colors.dart';
import '../models/activity_model.dart';

class RecentActivities extends StatelessWidget {
  final List<ActivityModel> activities;

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
              color: Colors.black,
            ),
          ),
        ),
        ...activities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
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
                  activity.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                activity.time,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Subtitle/description
          Text(
            activity.subtitle,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
