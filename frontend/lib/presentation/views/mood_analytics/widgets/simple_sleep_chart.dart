import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood_analytics_model.dart';

class SimpleSleepChart extends StatefulWidget {
  final SleepGraphResponse? sleepData;
  final bool isAnimated;

  const SimpleSleepChart({
    super.key,
    required this.sleepData,
    required this.isAnimated,
  });

  @override
  State<SimpleSleepChart> createState() => _SimpleSleepChartState();
}

class _SimpleSleepChartState extends State<SimpleSleepChart>
    with TickerProviderStateMixin {
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _barControllers = List.generate(
      7,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1200 + (index * 100)),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _fadeController.forward();

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
  void dispose() {
    _fadeController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prepare 7 days of sleep data
    final List<double> weeklyDurations = _prepareWeeklyData();
    final double yAxisMax = 20.0; // Fixed maximum Y-axis value

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
            Text(
              '7-Day Sleep Duration',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            SizedBox(
              height: 200.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final duration = weeklyDurations[index];
                  return _buildAnimatedBar(context, duration, index, yAxisMax);
                }),
              ),
            ),
            
            // X-axis line
            Container(
              height: 1,
              color: AppColors.textSecondary(context).withValues(alpha: 0.3),
            ),
            
            SizedBox(height: 8.h),
            
            // Day labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Text(
                        day,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _prepareWeeklyData() {
    final List<double> weeklyDurations = List.filled(7, 0.0);
    
    if (widget.sleepData?.graphData != null) {
      // Group by day and keep highest duration for duplicates
      final Map<String, double> dayDurations = {};
      
      for (final sleepData in widget.sleepData!.graphData) {
        final dayAbbr = _getDayAbbreviation(sleepData.dayOfWeek);
        if (!dayDurations.containsKey(dayAbbr) || 
            sleepData.duration > dayDurations[dayAbbr]!) {
          dayDurations[dayAbbr] = sleepData.duration;
        }
      }
      
      // Map to correct day indices
      const dayIndices = {
        'Sun': 0, 'Mon': 1, 'Tue': 2, 'Wed': 3, 
        'Thu': 4, 'Fri': 5, 'Sat': 6
      };
      
      dayDurations.forEach((day, duration) {
        final index = dayIndices[day];
        if (index != null) {
          weeklyDurations[index] = duration;
        }
      });
    }
    
    return weeklyDurations;
  }

  String _getDayAbbreviation(String fullDay) {
    final dayMap = {
      'Monday': 'Mon', 'Tuesday': 'Tue', 'Wednesday': 'Wed',
      'Thursday': 'Thu', 'Friday': 'Fri', 'Saturday': 'Sat', 'Sunday': 'Sun',
    };
    return dayMap[fullDay] ?? fullDay.substring(0, 3);
  }


  Widget _buildAnimatedBar(BuildContext context, double duration, int index, double yAxisMax) {
    return AnimatedBuilder(
      animation: _barAnimations[index],
      builder: (context, child) {
        // Calculate bar height as percentage of max duration (20 = max height)
        final maxHeight = 160.0; // Available height for bars
        final barHeight = duration > 0 ? (duration / yAxisMax) * maxHeight : 0.0;
        final animatedHeight = barHeight * _barAnimations[index].value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text positioned exactly on top of the bar
            if (_barAnimations[index].value > 0.1 && duration > 0)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  '${duration.toStringAsFixed(duration % 1 == 0 ? 0 : 1)}h',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary(context),
                  ),
                ),
              ),
            // Bar container
            Container(
              width: 24.w,
              height: duration > 0 ? (animatedHeight < 8 ? 8.0 : animatedHeight) : 0.0,
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
}