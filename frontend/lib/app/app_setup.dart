import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:yefa/data/repositories/audio_repository.dart';
import 'package:yefa/data/repositories/auth_repository.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'package:yefa/data/repositories/journal_repository.dart';
import 'package:yefa/data/repositories/user_repository.dart';
import 'package:yefa/data/services/audio_api_service.dart';
import 'package:yefa/data/services/auth_service.dart';
import 'package:yefa/data/services/challenge_api_service.dart';
import 'package:yefa/data/services/dio_service.dart';
import 'package:yefa/data/services/journal_api_service.dart';
import 'package:yefa/data/services/user_api_service.dart';

import '../core/utils/navigation_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/theme_service.dart';



final locator = GetIt.instance;

class AppSetup {
  static Future<void> setupServices() async {
    print('🚀 Starting service registration...');

    // Register navigation services
    print('📍 Registering navigation services...');
    locator.registerSingleton<NavigationService>(NavigationService());
    locator.registerSingleton(AppNavigationService());

    //  Register stacked services
    print('📱 Registering stacked services...');
    locator.registerSingleton(DialogService());
    locator.registerSingleton(SnackbarService());

    //  Register and initialize storage service 
    print('💾 Initializing storage service...');
    final storageService = StorageService();
    await storageService.init();
    locator.registerSingleton<StorageService>(storageService);

    //  Register theme service
    print('🎨 Registering theme service...');
    locator.registerSingleton<ThemeService>(ThemeService());

    // Register HTTP client service
    print('🌐 Registering HTTP client...');
    locator.registerLazySingleton<DioService>(() => DioService());

    //  Register API services (depend on DioService)
    print('🔌 Registering API services...');
    locator.registerLazySingleton<AuthApiService>(() => AuthApiService());
    locator.registerLazySingleton<AudioApiService>(() => AudioApiService());
    locator.registerLazySingleton<ChallengeApiService>(() => ChallengeApiService());
    locator.registerLazySingleton<UserApiService>(() => UserApiService());
    locator.registerLazySingleton<JournalApiService>(() => JournalApiService());

    //  Register repositories (depend on API services)
    print('📚 Registering repositories...');
    locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
    locator.registerLazySingleton<AudioRepository>(() => AudioRepository());
    locator.registerLazySingleton<ChallengeRepository>(() => ChallengeRepository());
    locator.registerLazySingleton<UserRepository>(() => UserRepository());
    locator.registerLazySingleton<JournalRepository>(() => JournalRepository());

    print('✅ All services registered successfully!');
    
    // Validate setup
    _validateServices();
  }

  // Helper method to validate all services are properly registered
  static void _validateServices() {
    try {
      print('🔍 Validating service registration...');
      
      // Test core services
      locator<StorageService>();
      locator<ThemeService>();
      locator<DioService>();
      
      // Test API services
      locator<AuthApiService>();
      locator<AudioApiService>();
      locator<ChallengeApiService>();
      locator<UserApiService>();
      locator<JournalApiService>();
      
      // Test repositories
      locator<AuthRepository>();
      locator<AudioRepository>();
      locator<ChallengeRepository>();
      locator<UserRepository>();
      locator<JournalRepository>();
      
      print('✅ All services validated successfully!');
    } catch (e) {
      print('❌ Service validation failed: $e');
      print('❌ Make sure all required files are created and imported correctly!');
    }
  }

  // Helper method to check if services are ready
  static bool get isInitialized {
    try {
      locator<StorageService>();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to reset services (useful for testing)
  static Future<void> reset() async {
    await locator.reset();
  }
}