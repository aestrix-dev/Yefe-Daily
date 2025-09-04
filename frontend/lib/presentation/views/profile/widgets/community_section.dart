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
              color: AppColors.textPrimary(context),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Community container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppColors.accentLight(context),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              // Yefa Man Cave
              _buildCommunityItem(
                iconPath: 'assets/icons/whatsapp.png',
                title: 'Yefa Man Cave',
                subtitle: 'Join our WhatsApp group',
                onTap: onYefaManCaveTap,
                showBottomBorder: true,
              ),

              // Towel Talk (Telegram)
              _buildCommunityItem(
                iconPath: 'assets/icons/telegram.png',
                title: 'Towel Talk',
                subtitle: 'Join our Telegram channel',
                onTap: onTowelTalkTap,
                showBottomBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityItem({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBottomBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Image.asset(
                  iconPath,
                  width: 44.w,
                  height: 44.h,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icons
                    IconData fallbackIcon;
                    Color fallbackColor;

                    if (iconPath.contains('whatsapp')) {
                      fallbackIcon = Icons.group;
                      fallbackColor = Colors.green;
                    } else if (iconPath.contains('telegram')) {
                      fallbackIcon = Icons.send;
                      fallbackColor = Colors.blue;
                    } else {
                      fallbackIcon = Icons.forum;
                      fallbackColor = Colors.blue;
                    }

                    return Icon(
                      fallbackIcon,
                      size: 20.sp,
                      color: fallbackColor,
                    );
                  },
                ),
              ),
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
                      color: Colors.grey[700],
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
