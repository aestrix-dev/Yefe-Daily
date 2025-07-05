import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/presentation/views/audio/models/audio_model.dart';

import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import 'audio_viewmodel.dart';
import 'widgets/audio_category_section.dart';
import 'widgets/audio_player_dialog.dart';

class AudioView extends StackedView<AudioViewModel> {
  const AudioView({super.key});

  @override
  Widget builder(
    BuildContext context,
    AudioViewModel viewModel,
    Widget? child,
  ) {
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
        backgroundColor: AppColors.accentDark,
        body: SafeArea(
          child: SingleChildScrollView(
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
                      color: Colors.black,
                    ),
                  ),
                ),

                // Audio Categories
                ...viewModel.audioCategories.map((category) {
                  return Column(
                    children: [
                      AudioCategorySection(
                        category: category,
                        onAudioTap: (audio) => _showAudioPlayer(context, audio),
                        onUpgradeTap: () =>
                            viewModel.toggleUpgradeCard(category.id),
                        showUpgradeCard:
                            viewModel.showUpgradeCardForCategory == category.id,
                        isPremiumUser: viewModel.isPremiumUser,
                        onUpgrade: viewModel.upgradeToPremium,
                      ),
                      SizedBox(height: 20.h),
                    ],
                  );
                }),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }

  void _showAudioPlayer(BuildContext context, AudioModel audio) {
    AudioPlayerBottomSheet.show(context, audio);
  }

  @override
  AudioViewModel viewModelBuilder(BuildContext context) => AudioViewModel();

  @override
  void onViewModelReady(AudioViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}
