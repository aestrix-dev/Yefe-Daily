import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood_analytics_model.dart';

class AnimatedMoodChart extends StatefulWidget {
  final WeeklyMoodData weeklyMoodData;
  final bool isAnimated;

  const AnimatedMoodChart({
    super.key,
    required this.weeklyMoodData,
    required this.isAnimated,
  });

  @override
  State<AnimatedMoodChart> createState() => _AnimatedMoodChartState();
}

class _AnimatedMoodChartState extends State<AnimatedMoodChart>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation for the entire chart
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Initialize bar animations
    _barControllers = List.generate(
      7,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1200 + (index * 100)),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller, 
          curve: Curves.elasticOut,
        ),
      );
    }).toList();

    // Start fade animation immediately
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(AnimatedMoodChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isAnimated && !oldWidget.isAnimated) {
      // Start staggered bar animations
      for (int i = 0; i < _barControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 150), () {
          if (mounted) {
            _barControllers[i].forward();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.accentLight(context),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart title
            Text(
              '7-Day Mood Trend',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Chart area - fixed height, no flex issues
            SizedBox(
              height: 200.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final mood = widget.weeklyMoodData.dailyMoods[index];
                  return _buildAnimatedBar(context, mood, index);
                }),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Y-axis labels
            Row(
              children: [
                SizedBox(width: 8.w),
                Text(
                  '1',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '20',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(BuildContext context, MoodAnalyticsModel mood, int index) {
    // Simple calculation - max height is 140, max value is 20
    final maxHeight = 140.0;
    final barHeight = (mood.moodValue / 20.0) * maxHeight;
    
    return AnimatedBuilder(
      animation: _barAnimations[index],
      builder: (context, child) {
        final animatedHeight = barHeight * _barAnimations[index].value;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mood value on top - simple sized box
            SizedBox(
              height: 18,
              child: _barAnimations[index].value > 0.8 
                ? Text(
                    mood.moodValue.toString(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary(context),
                    ),
                  )
                : null,
            ),
            
            // Animated bar - simple container with fixed dimensions
            Container(
              width: 24.w,
              height: animatedHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary(context),
                    AppColors.primary(context).withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary(context).withAlpha(77),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 6.h),
            
            // Day label
            Text(
              mood.dayOfWeek,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        );
      },
    );
  }
}