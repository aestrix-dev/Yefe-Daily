import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood_analytics_model.dart';
import '../mood_analytics_viewmodel.dart';

class AnimatedMoodChart extends StatefulWidget {
  final WeeklyMoodData weeklyMoodData;
  final bool isAnimated;
  final MoodAnalyticsViewModel? viewModel; // Add viewModel to check for real data

  const AnimatedMoodChart({
    super.key,
    required this.weeklyMoodData,
    required this.isAnimated,
    this.viewModel,
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
  late AnimationController _placeholderController;
  late Animation<double> _placeholderAnimation;

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

    // Initialize placeholder pulse animation for empty state
    _placeholderController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _placeholderAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _placeholderController, curve: Curves.easeInOut),
    );

    // Start placeholder animation for empty data states
    if (!(widget.viewModel?.hasRealSleepData ?? true)) {
      _placeholderController.repeat(reverse: true);
    }

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
    
    // Start bar animations immediately to prevent flat bars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _barControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 150), () {
          if (mounted) {
            _barControllers[i].forward();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedMoodChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Always start animations when data changes (fix for flat bars)
    if (widget.weeklyMoodData != oldWidget.weeklyMoodData || 
        (widget.isAnimated && !oldWidget.isAnimated)) {
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
    _placeholderController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maximum duration from the data for dynamic Y-axis scaling
    double maxDuration = 0.0;
    for (final mood in widget.weeklyMoodData.dailyMoods) {
      if (mood.moodValue > 0) {
        // Convert mood value back to actual sleep duration for scaling
        double actualDuration = _moodToSleepDuration(mood.moodValue);
        if (actualDuration > maxDuration) {
          maxDuration = actualDuration;
        }
      }
    }
    
    // Set minimum scale of 8 hours, or use max data + 1 for better visualization
    final double yAxisMax = maxDuration > 0 ? (maxDuration + 1).ceilToDouble() : 8.0;
    
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
              '7-Day Sleep Duration',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Chart area with Y-axis - proper graph layout
            SizedBox(
              height: 200.h,
              child: (widget.viewModel?.hasRealSleepData ?? true) 
                ? Row(
                    children: [
                      // Y-axis labels (dynamic scale based on data)
                      SizedBox(
                        width: 30.w,
                        height: 200.h,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildYAxisLabels(yAxisMax),
                        ),
                      ),
                      // Y-axis line
                      Container(
                        width: 1,
                        height: 200.h,
                        color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                      ),
                      SizedBox(width: 7.w),
                      // Chart bars
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) {
                            final mood = widget.weeklyMoodData.dailyMoods[index];
                            return _buildAnimatedBar(context, mood, index, yAxisMax);
                          }),
                        ),
                      ),
                    ],
                  )
                : _buildPlaceholderChart(context),
            ),
            
            // X-axis line
            Row(
              children: [
                SizedBox(width: 38.w), // Match Y-axis width (30w + 1w line + 7w space)
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            // X-axis with day labels - positioned right at the bottom of graph
            Row(
              children: [
                // Space for Y-axis alignment (30w + 1w line + 7w space = 38w)
                SizedBox(width: 38.w),
                // Day labels aligned with bars
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
                    ].map((day) => Text(
                      day,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(BuildContext context, MoodAnalyticsModel mood, int index, double yAxisMax) {
    // Convert mood value back to actual sleep duration for proper scaling
    final actualDuration = _moodToSleepDuration(mood.moodValue);
    
    // Debug logging
    
    // Use full available height (200h minus space for text above bars)
    final maxHeight = 180.0;
    final barHeight = actualDuration > 0 ? (actualDuration / yAxisMax) * maxHeight : 0.0;
    
    return AnimatedBuilder(
      animation: _barAnimations[index],
      builder: (context, child) {
        final animatedHeight = barHeight * _barAnimations[index].value;
        
        // Additional debug logging for Saturday (index 6)
        if (index == 6 && mood.moodValue > 0) {

        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sleep duration value on top - simple sized box
            SizedBox(
              height: 18,
              child: (_barAnimations[index].value > 0.1 && actualDuration > 0)
                ? Text(
                    '${actualDuration.toStringAsFixed(actualDuration % 1 == 0 ? 0 : 1)}h',
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
              height: actualDuration > 0 ? (animatedHeight < 10 ? 10.0 : animatedHeight) : 0.0,
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
          ],
        );
      },
    );
  }

  // Beautiful placeholder chart for when there's no sleep data
  Widget _buildPlaceholderChart(BuildContext context) {
    return AnimatedBuilder(
      animation: _placeholderAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder bars with pulsing animation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heights = [40.0, 60.0, 35.0, 80.0, 55.0, 45.0, 70.0];
                final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 18), // Space for values
                    // Placeholder bar with subtle pulse
                    Container(
                      width: 24.w,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withAlpha(
                          (50 + (150 * _placeholderAnimation.value)).round()
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Day labels
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context).withAlpha(
                          (100 + (100 * _placeholderAnimation.value)).round()
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            SizedBox(height: 20.h),
            
            // No data message with pulsing effect
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.textSecondary(context).withAlpha(
                  (20 + (30 * _placeholderAnimation.value)).round()
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 14.sp,
                    color: AppColors.textSecondary(context).withAlpha(
                      (120 + (80 * _placeholderAnimation.value)).round()
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'No sleep data yet',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary(context).withAlpha(
                        (120 + (80 * _placeholderAnimation.value)).round()
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Convert mood value back to actual sleep duration
  double _moodToSleepDuration(int moodValue) {
    if (moodValue == 0) return 0.0;
    if (moodValue >= 20) return 13.0; // Excellent sleep (9+ hours) - use max seen
    if (moodValue >= 18) return 8.5;  // Great sleep (8-9 hours)  
    if (moodValue >= 15) return 7.5;  // Good sleep (7-8 hours)
    if (moodValue >= 12) return 6.5;  // Okay sleep (6-7 hours)
    if (moodValue >= 8) return 5.5;   // Poor sleep (5-6 hours)
    return 4.0;  // Very poor sleep (<5 hours)
  }

  // Build dynamic Y-axis labels based on max duration
  List<Widget> _buildYAxisLabels(double yAxisMax) {
    final int steps = 5; // Number of labels to show
    final double stepSize = yAxisMax / (steps - 1);
    
    List<Widget> labels = [];
    for (int i = steps - 1; i >= 0; i--) {
      final double value = i * stepSize;
      labels.add(
        Text(
          value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 10.sp, 
            color: AppColors.textSecondary(context)
          ),
        ),
      );
    }
    return labels;
  }
}