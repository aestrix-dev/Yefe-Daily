import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_setup.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/storage_service.dart';

class OnboardingViewModel extends BaseViewModel {
  final _storageService = locator<StorageService>();

  final PageController pageController = PageController();
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  bool get isLastPage => _currentIndex == 2;

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

  // Add this method for going back
  void previousPage() {
    if (_currentIndex > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

 void completeOnboarding() {
    print('OnboardingViewModel: completeOnboarding called');

    _storageService.setBool('hasSeenOnboarding', true);
    _storageService.setBool('isLoggedIn', true);

    print('OnboardingViewModel: Storage values set');

    // Navigate to home page
    final context = StackedService.navigatorKey?.currentContext;
    if (context != null) {
      print('OnboardingViewModel: Context found, navigating to home');
      context.pushReplacement(AppRoutes.home);
    } else {
      print('OnboardingViewModel: ERROR - Context is null!');
    }
  }
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
