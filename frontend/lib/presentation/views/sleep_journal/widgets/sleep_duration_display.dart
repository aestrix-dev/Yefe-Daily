import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class SleepDurationDisplay extends StatelessWidget {
  final double duration;
  final String durationFormatted;
  final bool isValid;

  const SleepDurationDisplay({
    super.key,
    required this.duration,
    required this.durationFormatted,
    required this.isValid,
  });

  String _getSleepQualityMessage() {
    if (!isValid) return 'Invalid sleep duration';
    if (duration >= 8.5) return 'Excellent sleep duration! 😴✨';
    if (duration >= 7.5) return 'Great sleep duration! 🌙';
    if (duration >= 6.5) return 'Good sleep duration 💤';
    if (duration >= 5.5) return 'Could be better - aim for 7+ hours ⏰';
    return 'Too little sleep - prioritize rest! 🚨';
  }

  Color _getDurationColor(BuildContext context) {
    if (!isValid) return AppColors.error;
    if (duration >= 7.5) return AppColors.success;
    if (duration >= 6.5) return AppColors.primary(context);
    if (duration >= 5.5) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getDurationIcon() {
    if (!isValid) return Icons.error_outline;
    if (duration >= 8) return Icons.bedtime;
    if (duration >= 7) return Icons.nights_stay;
    if (duration >= 6) return Icons.dark_mode;
    return Icons.warning_amber_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final durationColor = _getDurationColor(context);
    final qualityMessage = _getSleepQualityMessage();
    final durationIcon = _getDurationIcon();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            durationColor.withAlpha(25),
            durationColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: durationColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Duration display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: durationColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Icon(
                  durationIcon,
                  size: 24.sp,
                  color: durationColor,
                ),
              ),
              
              SizedBox(width: 16.w),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Duration',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    durationFormatted,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: durationColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Quality message
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.accentLight(context),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              qualityMessage,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Sleep tips row
          Row(
            children: [
              Expanded(
                child: _buildTipItem(
                  context,
                  Icons.schedule,
                  'Optimal: 7-9h',
                  duration >= 7 && duration <= 9,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTipItem(
                  context,
                  Icons.trending_up,
                  'Consistent',
                  true, // We'll assume consistency for now
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTipItem(
                  context,
                  Icons.psychology,
                  'Quality',
                  duration >= 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isGood,
  ) {
    final color = isGood ? AppColors.success : AppColors.textSecondary(context);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isGood 
            ? AppColors.success.withAlpha(25) 
            : AppColors.textSecondary(context).withAlpha(25),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: color,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}