import 'package:stacked/stacked.dart';

import '../../../app/app_setup.dart';
import '../../../data/services/storage_service.dart';

class SplashViewModel extends BaseViewModel {
  final _storageService = locator<StorageService>();

  bool get hasSeenOnboarding =>
      _storageService.getBool('hasSeenOnboarding') ?? false;
  bool get isLoggedIn => _storageService.getBool('isLoggedIn') ?? false;
}
