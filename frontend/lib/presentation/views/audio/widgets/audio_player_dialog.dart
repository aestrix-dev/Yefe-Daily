import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yefa/data/models/audio_model.dart';
import 'package:yefa/data/services/audio_player_service.dart';
import '../../../../core/constants/app_colors.dart';

class AudioPlayerBottomSheet extends StatefulWidget {
  final AudioModel audio;
  final AudioPlayerService playerService;
  final VoidCallback onClose;
  final VoidCallback onPlayTap;
  final VoidCallback onPreviousTap;
  final VoidCallback onNextTap;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const AudioPlayerBottomSheet({
    super.key,
    required this.audio,
    required this.playerService,
    required this.onClose,
    required this.onPlayTap,
    required this.onPreviousTap,
    required this.onNextTap,
    required this.onSeekForward,
    required this.onSeekBackward,
  });

  @override
  State<AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    // Reset position streams when dialog opens for a new audio
    _resetProgressForNewAudio();
  }

  void _resetProgressForNewAudio() {
    // Check if the current audio in the service matches the dialog audio.
    final currentAudio = widget.playerService.currentAudio;
    if (currentAudio == null || currentAudio.id != widget.audio.id) {
      // If different audio or no audio, reset the player state

      // The progress will show zero until the new audio starts playing
    }
  }

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

          // Header with title (no download button as per your requirements)
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
              ],
            ),
          ),

          // Progress bar section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data ?? PositionData.zero;
                return Column(
                  children: [
                    // Progress bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary(context),
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: AppColors.primary(context),
                        overlayColor: AppColors.primary(
                          context,
                        ).withOpacity(0.2),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.r,
                        ),
                        trackHeight: 6.h,
                      ),
                      child: Slider(
                        value: positionData.position.inMilliseconds
                            .toDouble()
                            .clamp(
                              0.0,
                              positionData.duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1.0, double.infinity),
                            ),
                        max: positionData.duration.inMilliseconds
                            .toDouble()
                            .clamp(1.0, double.infinity),
                        onChanged: (value) {
                          widget.playerService.seek(
                            Duration(milliseconds: value.round()),
                          );
                        },
                      ),
                    ),

                    // Time labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(positionData.position),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(positionData.duration),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Control buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous button
                StreamBuilder<bool>(
                  stream: widget.playerService.playlist.map(
                    (_) => widget.playerService.hasPrevious,
                  ),
                  builder: (context, snapshot) {
                    final hasPrevious = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: hasPrevious ? widget.onPreviousTap : null,
                      child: Opacity(
                        opacity: hasPrevious ? 1.0 : 0.5,
                        child: Image.asset(
                          'assets/icons/previous.png',
                          width: 20.w,
                          height: 20.h,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.skip_previous,
                              size: 30.sp,
                              color: hasPrevious
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                // Rewind button
                GestureDetector(
                  onTap: widget.onSeekBackward,
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

                // Play/Pause button with loading state
                StreamBuilder<bool>(
                  stream: Rx.combineLatest2<bool, AudioModel?, bool>(
                    widget.playerService.audioPlayer.playingStream,
                    widget.playerService.playlist.map(
                      (_) => widget.playerService.currentAudio,
                    ),
                    (isPlaying, currentAudio) {
                      // Only show playing state if this dialog's audio is the current audio
                      return isPlaying && currentAudio?.id == widget.audio.id;
                    },
                  ),
                  builder: (context, playingSnapshot) {
                    final isPlaying = playingSnapshot.data ?? false;

                    return GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          widget.playerService.togglePlayPause();
                        } else {
                          setState(() => _isDownloading = true);
                          widget.onPlayTap();
                          // Reset downloading state after a delay (you might want to listen to actual completion)
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isDownloading = false);
                          });
                        }
                      },
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary(context),
                          shape: BoxShape.circle,
                        ),
                        child: _isDownloading
                            ? SizedBox(
                                width: 25.w,
                                height: 25.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 35.sp,
                                color: Colors.white,
                              ),
                      ),
                    );
                  },
                ),

                // Forward button
                GestureDetector(
                  onTap: widget.onSeekForward,
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
                StreamBuilder<bool>(
                  stream: widget.playerService.playlist.map(
                    (_) => widget.playerService.hasNext,
                  ),
                  builder: (context, snapshot) {
                    final hasNext = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: hasNext ? widget.onNextTap : null,
                      child: Opacity(
                        opacity: hasNext ? 1.0 : 0.5,
                        child: Image.asset(
                          'assets/icons/next.png',
                          width: 20.w,
                          height: 20.h,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.skip_next,
                              size: 10.sp,
                              color: hasNext
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest4<
        Duration,
        Duration,
        Duration?,
        AudioModel?,
        PositionData
      >(
        widget.playerService.audioPlayer.positionStream,
        widget.playerService.audioPlayer.bufferedPositionStream,
        widget.playerService.audioPlayer.durationStream,
        widget.playerService.playlist.map(
          (_) => widget.playerService.currentAudio,
        ),
        (position, bufferedPosition, duration, currentAudio) {
          // Only show progress if the current playing audio matches this dialog's audio
          final isCurrentAudio = currentAudio?.id == widget.audio.id;

          return PositionData(
            position: isCurrentAudio ? position : Duration.zero,
            bufferedPosition: isCurrentAudio ? bufferedPosition : Duration.zero,
            duration: isCurrentAudio
                ? (duration ?? Duration.zero)
                : Duration.zero,
          );
        },
      );

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

class PositionData {
  const PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  static const PositionData zero = PositionData(
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: Duration.zero,
  );
}
