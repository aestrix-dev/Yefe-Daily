import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/data/models/audio_model.dart';
import 'package:yefa/presentation/views/journal/widgets/upgrade_card.dart';
import '../../../../core/constants/app_colors.dart';

class AudioCategorySection extends StatelessWidget {
  final AudioCategoryModel category;
  final Function(AudioModel) onAudioTap;
  final VoidCallback onUpgradeTap;
  final VoidCallback onUpgrade;
  final bool showUpgradeCard;
  final bool isPremiumUser;

  const AudioCategorySection({
    super.key,
    required this.category,
    required this.onAudioTap,
    required this.onUpgradeTap,
    required this.onUpgrade,
    required this.showUpgradeCard,
    required this.isPremiumUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Title
          Text(
            category.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),

          SizedBox(height: 12.h),

          // Audio List
          ...category.audios.map((audio) => _buildAudioItem(context, audio)),

          // Upgrade Card (conditional)
          if (showUpgradeCard && !isPremiumUser) ...[
            SizedBox(height: 10.h),
            UpgradeCard(onUpgrade: onUpgrade),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioItem(BuildContext context, AudioModel audio) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: () => onAudioTap(audio),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.accentDark(context),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              // Play button
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.accentLight(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 20.sp,
                  color: Colors.grey[700],
                ),
              ),

              SizedBox(width: 12.w),

              // Audio info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      audio.duration,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (audio.subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        audio.subtitle!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Lock icon (right side)
              if (audio.isPremium && !isPremiumUser)
                GestureDetector(
                  onTap: onUpgradeTap,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Image.asset(
                      'assets/icons/unlock.png',
                      width: 32.w,
                      height: 32.h,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.lock,
                          size: 16.sp,
                          color: AppColors.accentLight(context),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
