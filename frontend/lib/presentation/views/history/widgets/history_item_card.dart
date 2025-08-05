import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/history_model.dart';

class HistoryItemCard extends StatelessWidget {
  final HistoryItemModel item;
  final VoidCallback onTap;

  const HistoryItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight(context),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatTimestamp(item.timestamp),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Description
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary(context),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12.h),

            // Status indicator
            Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  item.statusDisplayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(item.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 16.sp,
                  color: AppColors.textSecondary(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago, ${_formatTime(timestamp)}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago, ${_formatTime(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago, ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  Color _getStatusColor(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return AppColors.success;
      case HistoryStatus.inProgress:
        return AppColors.warning;
      case HistoryStatus.skipped:
        return AppColors.error;
    }
  }
}
