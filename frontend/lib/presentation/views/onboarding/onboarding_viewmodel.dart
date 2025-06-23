import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app_setup.dart';

import '../../../data/services/storage_service.dart';

class OnboardingViewModel extends BaseViewModel {
 
  final _storageService = locator<StorageService>();

  final PageController pageController = PageController();
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  bool get isLastPage => _currentIndex == 2; // 3 pages (0, 1, 2)

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (_currentIndex < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void completeOnboarding() {
    _storageService.setBool('hasSeenOnboarding', true);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
