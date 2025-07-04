import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yefa/core/constants/app_colors.dart';
import '../models/verse_model.dart';
import 'dart:ui';

class VerseCard extends StatelessWidget {
  final VerseModel verse;
  final VoidCallback? onBookmarkTap;

  const VerseCard({super.key, required this.verse, this.onBookmarkTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: Stack(
        children: [
        
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Opacity(
                opacity: 0.1, 
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),
          // Card content on top of background
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Verse of Today',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                    
                        GestureDetector(
                          onTap: () => _showVersePopup(context),
                          child: Image.asset(
                            'assets/icons/bulb.png',
                            width: 18.w,
                            height: 18.h,
                          ),
                        ),
                        SizedBox(width: 12.w),
                      
                        GestureDetector(
                          onTap: onBookmarkTap,
                          child: Image.asset(
                            'assets/icons/speaker.png',
                            width: 18.w,
                            height: 18.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Verse text
                Text(
                  verse.text,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.4,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                SizedBox(height: 8.h),

                // Reference - right aligned
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    verse.reference,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
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

  void _showVersePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const VersePopupDialog();
      },
    );
  }
}

class VersePopupDialog extends StatelessWidget {
  const VersePopupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // Popup card
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              // Removed shadow from popup too
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deeper Reflection',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

              
                Text(
                  'This verse reminds us that as men of faith, we are called to be courageous leaders. God promises to be with us through every challenge we face.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),

                
                SizedBox(height: 8.h),
                Text(
                  'Consider how you can demonstrate courage in your current circumstances. Where might God be calling you to step out in faith today?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
