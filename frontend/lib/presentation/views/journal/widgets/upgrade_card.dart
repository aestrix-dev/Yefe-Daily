import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class UpgradeCard extends StatelessWidget {
  final VoidCallback onUpgrade;

  const UpgradeCard({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      height: 180.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary(context).withOpacity(0.97),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/lock.png',
                        width: 20.w,
                        height: 20.h,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Yefa Plus',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for exclusive content, advanced features, and ad-free experience.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    height: 38.h,
                    child: ElevatedButton(
                      onPressed: onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                      ),
                      child: Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
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
}
