import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/navigation_service.dart';

import '../../../app/app_setup.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/storage_service.dart';

class SplashViewModel extends BaseViewModel {
  final _navigationService = locator<AppNavigationService>();
  final _storageService = locator<StorageService>();

  Future<void> handleStartup() async {
    await Future.delayed(const Duration(seconds: 2));

    final hasSeenOnboarding =
        _storageService.getBool('hasSeenOnboarding') ?? false;

    if (hasSeenOnboarding) {
      _navigationService.navigateToAndReplace(AppRoutes.home);
    } else {
      _navigationService.navigateToAndReplace(AppRoutes.onboarding);
    }
  }

  // Remove all override methods - just keep it simple
}
