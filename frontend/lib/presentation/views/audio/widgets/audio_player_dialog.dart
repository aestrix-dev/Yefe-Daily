import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/audio_model.dart';

class AudioPlayerBottomSheet extends StatefulWidget {
  final AudioModel audio;
  final VoidCallback onClose;

  const AudioPlayerBottomSheet({
    super.key,
    required this.audio,
    required this.onClose,
  });

  static void show(BuildContext context, AudioModel audio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 10,
      builder: (context) => AudioPlayerBottomSheet(
        audio: audio,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  bool isPlaying = false;
  double currentPosition = 25.0; // Mock current position
  double totalDuration = 100.0;
  String currentTime = '2:14';
  String totalTime = '10:00';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 20.h),

          // Header with title and download
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.audio.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (widget.audio.subtitle != null) ...[
                        // SizedBox(height: 4.h),
                        Text(
                          widget.audio.subtitle!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Download icon
                GestureDetector(
                  onTap: () {
                    print('Download audio: ${widget.audio.title}');
                  },
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/download.png',
                      width: 36.w,
                      height: 36.h,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.download,
                          size: 20.sp,
                          color: Colors.grey[700],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SizedBox(height: 40.h),

          // Progress bar section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary(context),
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: AppColors.primary(context),
                    overlayColor: AppColors.primary(context).withOpacity(0.2),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                    trackHeight: 6.h,
                  ),
                  child: Slider(
                    value: currentPosition,
                    max: totalDuration,
                    onChanged: (value) {
                      setState(() {
                        currentPosition = value;
                      });
                    },
                  ),
                ),

                // Time labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTime,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      totalTime,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SizedBox(height: 50.h),

          // Control buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous button
                GestureDetector(
                  onTap: () {
                    print('Previous track');
                  },
                  child: Image.asset(
                    'assets/icons/previous.png',
                    width: 20.w,
                    height: 20.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.skip_previous,
                        size: 30.sp,
                        color: Colors.grey[700],
                      );
                    },
                  ),
                ),

                // Rewind button
                GestureDetector(
                  onTap: () {
                    print('Rewind 10 seconds');
                  },
                  child: Image.asset(
                    'assets/icons/rewind.png',
                    width: 20.w,
                    height: 20.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.replay_10,
                        size: 20.sp,
                        color: Colors.grey[700],
                      );
                    },
                  ),
                ),

                // Play/Pause button (larger)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                    print(
                      '${isPlaying ? 'Playing' : 'Paused'}: ${widget.audio.audioUrl}',
                    );
                  },
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 35.sp,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Forward button
                GestureDetector(
                  onTap: () {
                    print('Forward 10 seconds');
                  },
                  child: Image.asset(
                    'assets/icons/forward.png',
                    width: 20.w,
                    height: 20.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.forward_10,
                        size: 15.sp,
                        color: Colors.grey[700],
                      );
                    },
                  ),
                ),

                // Next button
                GestureDetector(
                  onTap: () {
                    print('Next track');
                  },
                  child: Image.asset(
                    'assets/icons/next.png',
                    width: 20.w,
                    height: 20.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.skip_next,
                        size: 10.sp,
                        color: Colors.grey[700],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        
        ],
      ),
    );
  }
}
