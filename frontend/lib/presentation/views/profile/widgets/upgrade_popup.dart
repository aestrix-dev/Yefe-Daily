import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';

class UpgradePopup extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onCancel;

  const UpgradePopup({
    super.key,
    required this.onUpgrade,
    required this.onCancel,
  });

  static void show(BuildContext context, {required VoidCallback onUpgrade}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => UpgradePopup(
        onUpgrade: () {
          Navigator.of(context).pop();
          onUpgrade();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main popup content
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Stack(
                  children: [
                    // Background image with blur (lowest z-index)
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary(context).withOpacity(0.8),
                                  AppColors.primary(context).withOpacity(0.6),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Blur effect
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Semi-transparent overlay (middle z-index)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withOpacity(0.97),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with title and price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/lock.png',
                                      width: 26.w,
                                      height: 26.h,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.lock,
                                              size: 26.sp,
                                              color: Colors.grey[300],
                                            );
                                          },
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Yefa Plus',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$5 /3months',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24.h),

                            // Feature bullet points
                            _buildFeature(
                              'Evening journal prompts',
                            ),
                            _buildFeature(
                              'Voice journaling',
                            ),
                            _buildFeature('30 Days mood analytics'),
                            _buildFeature(
                              'All Towel Talks episodes',
                            ),
                            _buildFeature(
                              'Private journal entries',
                            ),
                            

                            SizedBox(height: 24.h),

                            // Upgrade button
                            SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: onUpgrade,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryLight(
                                    context,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                ),
                                child: Text(
                                  'Upgrade to Yefa Plus',
                                  style: TextStyle(
                                    fontSize: 16.sp,
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
              ),
            ),

            // Cancel button (outside the popup)
            Positioned(
              top: -10.h,
              right: 10.w,
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            margin: EdgeInsets.only(top: 6.h, right: 12.w),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
