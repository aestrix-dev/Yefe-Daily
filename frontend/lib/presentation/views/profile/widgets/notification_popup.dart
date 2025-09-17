import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationPopup extends StatefulWidget {
  final bool isEnabled;
  final VoidCallback onEnable;
  final VoidCallback onCancel;

  const NotificationPopup({
    super.key,
    required this.isEnabled,
    required this.onEnable,
    required this.onCancel,
  });

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleEnable() async {
    setState(() {
      _isLoading = true;
    });

    // Call the enable function
    widget.onEnable();
  }

  void _handleSuccess() {
    // Animation out and close
    _scaleController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleError() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.accentLight(context),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animation
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: widget.isEnabled
                        ? AppColors.primary(context).withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    size: 40.sp,
                    color: widget.isEnabled
                        ? AppColors.primary(context)
                        : AppColors.error,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  widget.isEnabled
                      ? 'Disable Notifications?'
                      : 'Enable Notifications?',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                // Description
                Text(
                  widget.isEnabled
                      ? 'You will no longer receive daily devotionals, challenges, and reminders.'
                      : 'Stay connected with daily devotionals, challenges, and gentle reminders to help you grow in faith.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : widget.onCancel,
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.accentDark(context),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.textSecondary(context)
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Action button
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleEnable,
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: widget.isEnabled
                                ? AppColors.error
                                : AppColors.primary(context),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    widget.isEnabled ? 'Disable' : 'Enable',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Public methods to be called from parent
  void showSuccess() => _handleSuccess();
  void showError() => _handleError();
}