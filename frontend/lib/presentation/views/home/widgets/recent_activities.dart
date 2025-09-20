import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/core/constants/app_colors.dart';
import 'package:yefa/data/models/journal_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RecentActivities extends StatelessWidget {
  final List<JournalModel> activities;

  const RecentActivities({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        if (activities.isEmpty)
          _buildEmptyState(context)
        else
          ...activities.map(
            (activity) => _buildActivityItem(context, activity),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 32.sp,
              color: AppColors.textSecondary(context),
            ),
            SizedBox(height: 8.h),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your spiritual activities will appear here',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, JournalModel activity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left container (80% width) - Title and content stacked
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatActivityTitle(activity),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      activity.content,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Right container (20% width) - Timestamp and share icon stacked
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(activity.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () => _showShareBottomSheet(context, activity),
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.share,
                          size: 14.sp,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatActivityTitle(JournalModel activity) {
    // Format the type properly
    String formattedType;
    switch (activity.type.toLowerCase()) {
      case 'wisdom_note':
        formattedType = 'Wisdom';
        break;
      case 'morning':
        formattedType = 'Morning';
        break;
      case 'evening':
        formattedType = 'Evening';
        break;
      default:
        formattedType = activity.type.isNotEmpty
            ? activity.type[0].toUpperCase() + activity.type.substring(1)
            : '';
    }

    // Get first tag if available
    String firstTag = '';
    if (activity.tags.isNotEmpty) {
      firstTag = ' • ${activity.tags[0]}';
    }

    return '$formattedType Reflection$firstTag';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "Aug 15"
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _showShareBottomSheet(BuildContext context, JournalModel activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.accentLight(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Share reflection',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),

            // Share options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // WhatsApp option
                  _buildShareOption(
                    context,
                    icon: 'assets/icons/whatsapp.png',
                    fallbackIcon: Icons.message,
                    fallbackColor: Colors.green,
                    label: 'WhatsApp',
                    onTap: () {
                      Navigator.pop(context);
                      _shareToWhatsApp(activity);
                    },
                  ),

                  // Telegram option
                  _buildShareOption(
                    context,
                    icon: 'assets/icons/telegram.png',
                    fallbackIcon: Icons.send,
                    fallbackColor: Colors.blue,
                    label: 'Telegram',
                    onTap: () {
                      Navigator.pop(context);
                      _shareToTelegram(activity);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required String icon,
    required IconData fallbackIcon,
    required Color fallbackColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: AppColors.accentDark(context),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Center(
              child: Image.asset(
                icon,
                width: 32.w,
                height: 32.h,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: 32.sp,
                    color: fallbackColor,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToWhatsApp(JournalModel activity) async {
    try {
      final shareText = _buildShareText(activity);
      final encodedText = Uri.encodeComponent(shareText);
      final whatsappUrl = 'https://wa.me/?text=$encodedText';

      final uri = Uri.parse(whatsappUrl);

      // Try multiple approaches to open WhatsApp
      bool opened = false;

      // 1. Try to open with external application (will open WhatsApp if installed)
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {

          return;
        }
      } catch (e) {

      }

      // 2. Try with platformDefault mode
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (opened) {

          return;
        }
      } catch (e) {

      }

      // 3. Final fallback - open in web browser
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );

    } catch (e) {

    }
  }

  Future<void> _shareToTelegram(JournalModel activity) async {
    try {
      final shareText = _buildShareText(activity);
      final encodedText = Uri.encodeComponent(shareText);
      final telegramUrl = 'https://t.me/share/url?text=$encodedText';

      final uri = Uri.parse(telegramUrl);

      // Try multiple approaches to open Telegram
      bool opened = false;

      // 1. Try to open with external application (will open Telegram if installed)
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {

          return;
        }
      } catch (e) {

      }

      // 2. Try with platformDefault mode
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (opened) {

          return;
        }
      } catch (e) {

      }

      // 3. Final fallback - open in web browser
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );

    } catch (e) {

    }
  }

  String _buildShareText(JournalModel activity) {
    final title = _formatActivityTitle(activity);
    final formattedDate = DateFormat('MMM d, yyyy').format(activity.createdAt);

    return '''
$title

"${activity.content}"

Shared from Yefa Daily App
Date: $formattedDate

Download Yefa Daily: [https://www.yefadaily.com]
''';
  }
}
