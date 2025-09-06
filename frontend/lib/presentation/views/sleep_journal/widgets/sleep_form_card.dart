import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class SleepFormCard extends StatelessWidget {
  final String sleptDate;
  final String sleptTime;
  final String wokeUpDate;
  final String wokeUpTime;
  final VoidCallback onSleptDateTap;
  final VoidCallback onSleptTimeTap;
  final VoidCallback onWokeUpDateTap;
  final VoidCallback onWokeUpTimeTap;

  const SleepFormCard({
    super.key,
    required this.sleptDate,
    required this.sleptTime,
    required this.wokeUpDate,
    required this.wokeUpTime,
    required this.onSleptDateTap,
    required this.onSleptTimeTap,
    required this.onWokeUpDateTap,
    required this.onWokeUpTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.edit_calendar,
                  size: 16.sp,
                  color: AppColors.primary(context),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Sleep Details',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),

          // Bedtime Section
          _buildSectionHeader(
            context: context,
            icon: Icons.bedtime_outlined,
            title: 'Bedtime',
            subtitle: 'When did you go to sleep?',
          ),
          
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Date',
                  value: sleptDate,
                  icon: Icons.calendar_today,
                  onTap: onSleptDateTap,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Time',
                  value: sleptTime,
                  icon: Icons.access_time,
                  onTap: onSleptTimeTap,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),

          // Wake up Section
          _buildSectionHeader(
            context: context,
            icon: Icons.wb_sunny_outlined,
            title: 'Wake Up',
            subtitle: 'When did you wake up?',
          ),
          
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Date',
                  value: wokeUpDate,
                  icon: Icons.calendar_today,
                  onTap: onWokeUpDateTap,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Time',
                  value: wokeUpTime,
                  icon: Icons.access_time,
                  onTap: onWokeUpTimeTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: AppColors.primary(context),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.accentDark(context),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.textSecondary(context).withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14.sp,
                  color: AppColors.textSecondary(context),
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}