import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class CommunitySection extends StatelessWidget {
  final VoidCallback onYefaManCaveTap;
  final VoidCallback onTowelTalkTap;

  const CommunitySection({
    super.key,
    required this.onYefaManCaveTap,
    required this.onTowelTalkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Community title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Community',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Yefa Man Cave
        _buildCommunityItem(
          icon: Icons.group,
          iconColor: Colors.green,
          title: 'Yefa Man Cave',
          subtitle: 'Join our WhatsApp group',
          onTap: onYefaManCaveTap,
        ),

        // Towel Talk
        _buildCommunityItem(
          icon: Icons.forum,
          iconColor: AppColors.primary,
          title: 'Towel Talk',
          subtitle: 'Watch our latest videos',
          onTap: onTowelTalkTap,
        ),
      ],
    );
  }

  Widget _buildCommunityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 20.sp, color: iconColor),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20.sp),
          ],
        ),
      ),
    );
  }
}
