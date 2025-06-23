import 'package:flutter/material.dart';

import '../../app/app_setup.dart';
import 'storage_service.dart';

class ThemeService {
  final _storageService = locator<StorageService>();
  late ValueNotifier<ThemeMode> _themeModeNotifier;

  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  ThemeService() {
    final isDarkMode = _storageService.getBool('isDarkMode') ?? false;
    _themeModeNotifier = ValueNotifier(
      isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void toggleTheme() {
    final isDarkMode = _themeModeNotifier.value == ThemeMode.dark;
    _themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _storageService.setBool('isDarkMode', !isDarkMode);
  }

  bool get isDarkMode => _themeModeNotifier.value == ThemeMode.dark;
}
