import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

enum ToastType { success, error, warning, info }

class ToastNotification extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const ToastNotification({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<ToastNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Slide from right animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Progress bar animation
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Start animations
    _slideController.forward();
    _progressController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _slideController.reverse();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.primary(context); // Use app's primary color for success
      case ToastType.error:
        return const Color(0xFFD32F2F); // Custom red that matches app theme
      case ToastType.warning:
        return const Color(0xFFF57C00); // Custom orange that matches app theme
      case ToastType.info:
        return AppColors.primary(context);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10.h,
          right: 16.w,
          left: 16.w,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Icon
                  Icon(_getIcon(), color: Colors.white, size: 20.sp),

                  SizedBox(width: 12.w),

                  // Message
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Dismiss button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.4),
                  ),
                  minHeight: 3.h,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ToastOverlay {
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      // Remove existing toast if any
      hide();

      // Find the overlay - try multiple approaches
      OverlayState? overlay;

      // First try: get overlay directly
      try {
        overlay = Overlay.of(context);
      } catch (e) {
        print('First overlay attempt failed: $e');
      }

      // Second try: get from navigator context
      if (overlay == null) {
        try {
          final navigatorContext = Navigator.of(context).context;
          overlay = Overlay.of(navigatorContext);
        } catch (e) {
          print('Second overlay attempt failed: $e');
        }
      }

      // Third try: get from root overlay
      if (overlay == null) {
        try {
          overlay = Overlay.of(context, rootOverlay: true);
        } catch (e) {
          print('Third overlay attempt failed: $e');
        }
      }

      if (overlay == null) {
        print('❌ Could not find overlay, falling back to console log');
        print('Toast: [$type] $message');
        return;
      }

      _currentOverlay = OverlayEntry(
        builder: (context) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: ToastNotification(
              message: message,
              type: type,
              duration: duration,
              onDismiss: () {
                hide();
              },
            ),
          ),
        ),
      );

      overlay.insert(_currentOverlay!);
    } catch (e) {
      print('❌ Error showing toast: $e');
      print('Toast fallback: [$type] $message');
    }
  }

  static void hide() {
    try {
      _currentOverlay?.remove();
      _currentOverlay = null;
    } catch (e) {
      print('Error hiding toast: $e');
    }
  }

  // Convenience methods
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }
}
