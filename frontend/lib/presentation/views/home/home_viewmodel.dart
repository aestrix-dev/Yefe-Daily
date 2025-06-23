import 'package:stacked/stacked.dart';

import '../../../app/app_setup.dart';
import '../../../data/services/theme_service.dart';

class HomeViewModel extends BaseViewModel {
  final _themeService = locator<ThemeService>();

  bool get isDarkMode => _themeService.isDarkMode;

  void toggleTheme() {
    _themeService.toggleTheme();
    notifyListeners();
  }
}
