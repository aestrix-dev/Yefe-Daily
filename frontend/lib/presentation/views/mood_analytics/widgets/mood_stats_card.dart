import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood_analytics_model.dart';

class MoodStatsCard extends StatelessWidget {
  final WeeklyMoodData weeklyMoodData;
  final String insight;

  const MoodStatsCard({
    super.key,
    required this.weeklyMoodData,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Average',
                  weeklyMoodData.averageMood.toStringAsFixed(1),
                  Icons.trending_up,
                  AppColors.primary(context),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              Expanded(
                child: _buildStatItem(
                  context,
                  'Highest',
                  weeklyMoodData.highestMood.toString(),
                  Icons.keyboard_arrow_up,
                  const Color(0xFF4CAF50),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              Expanded(
                child: _buildStatItem(
                  context,
                  'Lowest',
                  weeklyMoodData.lowestMood.toString(),
                  Icons.keyboard_arrow_down,
                  const Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Insight section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary(context).withAlpha(15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary(context).withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18.sp,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        
        SizedBox(height: 4.h),
        
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}