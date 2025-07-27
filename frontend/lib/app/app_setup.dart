import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';

import '../core/utils/navigation_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/theme_service.dart';

final locator = GetIt.instance;

class AppSetup {
  static Future<void> setupServices() async {
    // Register navigator key with NavigationService
    locator.registerSingleton<NavigationService>(NavigationService());

    // Register navigation service
    locator.registerSingleton(AppNavigationService());

    // Register stacked services
    locator.registerSingleton(DialogService());
    locator.registerSingleton(SnackbarService());

    // Register storage service
    final storageService = StorageService();
    await storageService.init();
    locator.registerSingleton<StorageService>(storageService);

    // Register theme service
    locator.registerSingleton<ThemeService>(ThemeService());
  }
}
