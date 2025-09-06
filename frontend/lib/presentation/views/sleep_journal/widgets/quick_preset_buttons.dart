import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class QuickPresetButtons extends StatelessWidget {
  final VoidCallback onPreset7Hours;
  final VoidCallback onPreset8Hours;
  final VoidCallback onPreset9Hours;

  const QuickPresetButtons({
    super.key,
    required this.onPreset7Hours,
    required this.onPreset8Hours,
    required this.onPreset9Hours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 16.sp,
                color: AppColors.primary(context),
              ),
              SizedBox(width: 8.w),
              Text(
                'Quick Presets',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Expanded(
                child: _buildPresetButton(
                  context: context,
                  label: '7 Hours',
                  subtitle: '11 PM - 6 AM',
                  icon: Icons.schedule,
                  onTap: onPreset7Hours,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPresetButton(
                  context: context,
                  label: '8 Hours',
                  subtitle: '10 PM - 6 AM',
                  icon: Icons.bedtime,
                  onTap: onPreset8Hours,
                  isRecommended: true,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildPresetButton(
                  context: context,
                  label: '9 Hours',
                  subtitle: '9 PM - 6 AM',
                  icon: Icons.nights_stay,
                  onTap: onPreset9Hours,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isRecommended 
              ? AppColors.primary(context).withAlpha(25)
              : AppColors.accentDark(context),
          borderRadius: BorderRadius.circular(8.r),
          border: isRecommended
              ? Border.all(color: AppColors.primary(context).withAlpha(100))
              : null,
        ),
        child: Column(
          children: [
            if (isRecommended) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary(context),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
            ],
            
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isRecommended
                    ? AppColors.primary(context).withAlpha(50)
                    : AppColors.primary(context).withAlpha(25),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                icon,
                size: 16.sp,
                color: AppColors.primary(context),
              ),
            ),
            
            SizedBox(height: 6.h),
            
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            
            SizedBox(height: 2.h),
            
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}