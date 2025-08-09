import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/data/models/audio_model.dart';


import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import 'audio_viewmodel.dart';
import 'widgets/audio_category_section.dart';

class AudioView extends StackedView<AudioViewModel> {
  const AudioView({super.key});

  @override
  Widget builder(
    BuildContext context,
    AudioViewModel viewModel,
    Widget? child,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!viewModel.contextAlreadySet) {
        viewModel.setContext(context);
      }
    });

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.accentDark(context),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: viewModel.refresh,
            color: AppColors.primary(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      'Devotional Audio',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),

                  // Error message
                  if (viewModel.errorMessage != null)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(12.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: viewModel.refresh,
                            child: Icon(
                              Icons.refresh,
                              color: Colors.red,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: viewModel.errorMessage != null ? 16.h : 0),

                  // Loading indicator
                  if (viewModel.isLoading && viewModel.audioCategories.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.h),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary(context),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Loading audio content...',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Audio Categories (Single Tower Talk category)
                  if (viewModel.audioCategories.isNotEmpty)
                    ...viewModel.audioCategories.map((category) {
                      return Column(
                        children: [
                          AudioCategorySection(
                            category: category,
                            onAudioTap: (audio) =>
                                viewModel.handleAudioTap(audio),
                            onUpgradeTap: () =>
                                viewModel.toggleUpgradeCard(category.id),
                            showUpgradeCard:
                                viewModel.showUpgradeCardForCategory ==
                                category.id,
                            isPremiumUser: viewModel.isPremiumUser,
                            onUpgrade: viewModel.showPaymentSheet,
                          ),
                          SizedBox(height: 20.h),
                        ],
                      );
                    }),

                  // Empty state
                  if (!viewModel.isLoading &&
                      viewModel.audioCategories.isEmpty &&
                      viewModel.errorMessage == null)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.h),
                        child: Column(
                          children: [
                            Icon(
                              Icons.music_note_outlined,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No audio content available',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Pull down to refresh',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 100.h), // Extra space for floating player
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),

        // Floating mini player (shows when audio is playing)
        floatingActionButton: StreamBuilder<AudioModel?>(
          stream: viewModel.playerService.playlist.map(
            (_) => viewModel.playerService.currentAudio,
          ),
          builder: (context, snapshot) {
            final currentAudio = snapshot.data;
            if (currentAudio == null) return const SizedBox.shrink();

            return StreamBuilder<bool>(
              stream: viewModel.playerService.audioPlayer.playingStream,
              builder: (context, playingSnapshot) {
                final isPlaying = playingSnapshot.data ?? false;

                return Container(
                  margin: EdgeInsets.only(bottom: 80.h), // Above bottom nav
                  child: FloatingActionButton.extended(
                    onPressed: () => viewModel.handleAudioTap(currentAudio),
                    backgroundColor: AppColors.primary(context),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 120.w,
                          child: Text(
                            currentAudio.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  AudioViewModel viewModelBuilder(BuildContext context) => AudioViewModel();

  @override
  void onViewModelReady(AudioViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}
