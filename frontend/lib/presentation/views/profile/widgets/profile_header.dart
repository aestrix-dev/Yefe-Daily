import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userPlan;
  final String avatarUrl;
  final VoidCallback onUpgrade;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userPlan,
    required this.avatarUrl,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = userPlan == 'Yefa +';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isPremium ? AppColors.primary : Colors.grey[300]!,
                width: 2.w,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 30.sp,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (isPremium) ...[
                      Image.asset(
                        'assets/images/Crown.png',
                        width: 16.w,
                        height: 16.h,
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Text(
                      userPlan,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isPremium ? AppColors.primary : Colors.grey[600],
                        fontWeight: isPremium
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Upgrade button (only show if not premium)
          if (!isPremium)
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/Crown.png',
                      width: 16.w,
                      height: 16.h,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Upgrade',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
