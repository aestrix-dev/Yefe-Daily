import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/constants/app_routes.dart';
import 'package:yefa/data/model/onboarding_model.dart';

import '../../../app/app_setup.dart';
import '../../../core/utils/navigation_service.dart';
import '../../../data/services/storage_service.dart';

class OnboardingViewModel extends BaseViewModel {
  final _navigationService = locator<AppNavigationService>();
  final _storageService = locator<StorageService>();

  final PageController pageController = PageController();
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  bool get isLastPage => _currentIndex == onboardingPages.length - 1;

  final List<OnboardingModel> onboardingPages = [
    const OnboardingModel(
      title: 'Welcome to Our App',
      description: 'Discover amazing features that will make your life easier.',
      imagePath: 'assets/images/onboarding1.png',
    ),
    const OnboardingModel(
      title: 'Stay Connected',
      description: 'Connect with friends and family like never before.',
      imagePath: 'assets/images/onboarding2.png',
    ),
    const OnboardingModel(
      title: 'Get Started',
      description: 'Ready to begin your journey? Let\'s get started!',
      imagePath: 'assets/images/onboarding3.png',
    ),
  ];

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (_currentIndex < onboardingPages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_currentIndex > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    completeOnboarding();
  }

  void completeOnboarding() {
    _storageService.setBool('hasSeenOnboarding', true);
    _navigationService.navigateToAndReplace(AppRoutes.home);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
