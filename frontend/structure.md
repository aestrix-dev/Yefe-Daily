# Flutter Base Architecture Structure (Yefa Daily)

A comprehensive Flutter project architecture using **Stacked MVVM** pattern with service locator dependency injection.

## Project Structure

```
lib/
├── main.dart                          # App entry point with Firebase & audio service initialization
├── firebase_options.dart             # Firebase configuration
├── app/
│   ├── app.dart                       # Main app widget configuration
│   ├── app_setup.dart                 # Service registration and dependency injection setup
│   └── router/
│       └── app_router.dart            # Navigation routing configuration
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Color palette definitions
│   │   ├── app_routes.dart            # Route path constants
│   │   ├── app_sizes.dart             # Responsive sizing constants
│   │   ├── app_strings.dart           # String constants and labels
│   │   └── route_names.dart           # Named route definitions
│   ├── enums/
│   │   └── view_state.dart            # View state enums (loading, error, etc.)
│   ├── exceptions/
│   │   └── app_exceptions.dart        # Custom exception classes
│   ├── extensions/
│   │   ├── context_extensions.dart    # BuildContext extension methods
│   │   ├── string_extensions.dart     # String extension methods
│   │   └── theme_extensions.dart      # Theme extension methods
│   ├── utils/
│   │   ├── api_result.dart           # Result wrapper for API responses
│   │   ├── device_utils.dart         # Device-related utilities
│   │   ├── firebase_background_handler.dart # FCM background message handler
│   │   ├── navigation_helper.dart     # Navigation helper methods
│   │   ├── navigation_service.dart    # Custom navigation service
│   │   ├── page_transitions.dart     # Custom page transition animations
│   │   └── validators.dart           # Form validation utilities
│   └── examples/                     # Usage examples and integration guides
│       ├── fcm_integration_example.dart
│       ├── notification_test_example.dart
│       └── notification_usage_example.dart
├── data/
│   ├── models/                       # Data models (DTOs)
│   │   ├── audio_model.dart
│   │   ├── challenge_model.dart
│   │   ├── journal_model.dart
│   │   ├── user_model.dart
│   │   └── [feature]_model.dart
│   ├── repositories/                 # Repository pattern implementations
│   │   ├── base_repository.dart      # Base repository with common error handling
│   │   ├── audio_repository.dart
│   │   ├── auth_repository.dart
│   │   ├── challenge_repository.dart
│   │   ├── journal_repository.dart
│   │   ├── payment_repository.dart
│   │   ├── reflection_repository.dart
│   │   ├── sleep_repository.dart
│   │   └── user_repository.dart
│   ├── services/                     # Business logic services
│   │   ├── audio_api_service.dart    # Audio-related API calls
│   │   ├── audio_download_service.dart # Audio file management
│   │   ├── audio_player_service.dart  # Audio playback service
│   │   ├── auth_service.dart         # Authentication service
│   │   ├── challenge_api_service.dart
│   │   ├── dio_service.dart          # HTTP client configuration
│   │   ├── firebase_notification_service.dart # FCM integration
│   │   ├── journal_api_service.dart
│   │   ├── payment_api_service.dart
│   │   ├── payment_service.dart      # Stripe payment integration
│   │   ├── premium_status_service.dart
│   │   ├── puzzle_timer_service.dart
│   │   ├── reflection_api_service.dart
│   │   ├── sleep_api_service.dart
│   │   ├── storage_service.dart      # Local storage wrapper
│   │   ├── theme_service.dart        # Theme management
│   │   ├── toast_service.dart        # Toast notifications
│   │   ├── user_api_service.dart
│   │   └── cache/                    # Caching services
│   │       └── home_cache.dart
│   └── widgets/                      # Data layer specific widgets
├── presentation/
│   ├── shared/                       # Shared UI components
│   │   ├── themes/                   # App theme definitions
│   │   │   ├── app_theme.dart
│   │   │   ├── dark_theme.dart
│   │   │   └── light_theme.dart
│   │   └── widgets/                  # Reusable widgets
│   │       ├── custom_button.dart
│   │       ├── loading_widget.dart
│   │       ├── error_widget.dart
│   │       └── [shared_widget].dart
│   └── views/                        # Feature-specific UI
│       ├── [feature_name]/
│       │   ├── [feature]_view.dart        # UI view (extends StackedView)
│       │   ├── [feature]_viewmodel.dart   # Business logic (extends BaseViewModel)
│       │   ├── models/                    # Feature-specific models
│       │   │   └── [feature]_model.dart
│       │   └── widgets/                   # Feature-specific widgets
│       │       └── [feature]_widget.dart
│       ├── audio/
│       ├── challenges/
│       ├── history/
│       ├── home/
│       ├── journal/
│       ├── mood_analytics/
│       ├── onboarding/
│       ├── profile/
│       ├── sleep_journal/
│       └── splash/
└── assets/                          # Static assets
    ├── images/
    ├── icons/
    └── fonts/
```

## Dependencies (pubspec.yaml)

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase Integration
  firebase_core: ^4.1.0
  firebase_messaging: ^16.0.1
  flutter_local_notifications: ^17.2.3

  # Payment Integration
  webview_flutter: ^4.4.2
  flutter_stripe: ^10.1.0

  # Audio Services
  just_audio: ^0.9.39
  audio_service: ^0.18.13
  rxdart: ^0.27.7
  path_provider: ^2.1.4
  crypto: ^3.0.3

  # State Management & Architecture (Stacked MVVM)
  stacked: ^3.4.2
  stacked_services: ^1.2.0
  get_it: ^7.6.4                     # Service locator dependency injection

  # Navigation
  go_router: ^12.1.3

  # Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Network
  dio: ^5.3.2
  connectivity_plus: ^5.0.2
  pretty_dio_logger: ^1.3.1
  json_annotation: ^4.8.1

  # UI
  flutter_screenutil: ^5.9.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

  # Utils
  logger: ^2.0.2+1
  equatable: ^2.0.5
  url_launcher: ^6.2.2
  intl: ^0.17.0

dev_dependencies:
  # Code Generation
  auto_route_generator: ^7.3.2
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1

  # Icon generation
  flutter_launcher_icons: ^0.13.1

  flutter_lints: ^5.0.0
```

## Core Architecture Components

### 1. Main App Entry Point (main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/app.dart';
import 'app/app_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Setup all services using dependency injection
  await AppSetup.setupServices();

  // Initialize audio service for background playback
  await _initializeAudioService();

  // Configure Stripe
  Stripe.publishableKey = 'your_publishable_key';

  runApp(const MyApp());
}
```

### 2. Service Registration (app/app_setup.dart)

```dart
import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';

final locator = GetIt.instance;

class AppSetup {
  static Future<void> setupServices() async {
    // Register core services
    locator.registerSingleton<NavigationService>(NavigationService());
    locator.registerSingleton(DialogService());
    locator.registerSingleton(SnackbarService());

    // Register and initialize storage service
    final storageService = StorageService();
    await storageService.init();
    locator.registerSingleton<StorageService>(storageService);

    // Register business services
    locator.registerLazySingleton<DioService>(() => DioService());
    locator.registerSingleton<AudioPlayerService>(AudioPlayerService());
    locator.registerSingleton<FirebaseNotificationService>(notificationService);

    // Register API services
    locator.registerLazySingleton<AuthApiService>(() => AuthApiService());
    locator.registerLazySingleton<AudioApiService>(() => AudioApiService());
    locator.registerLazySingleton<ChallengeApiService>(() => ChallengeApiService());

    // Register repositories
    locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
    locator.registerLazySingleton<AudioRepository>(() => AudioRepository());
    locator.registerLazySingleton<ChallengeRepository>(() => ChallengeRepository());
  }
}
```

### 3. API Result Wrapper (core/utils/api_result.dart)

```dart
abstract class ApiResult<T> {
  const ApiResult();
}

class Success<T> extends ApiResult<T> {
  final T data;
  final String? message;
  const Success(this.data, {this.message});
}

class Failure<T> extends ApiResult<T> {
  final String error;
  final int? statusCode;
  const Failure(this.error, {this.statusCode});
}

// Extension for easier handling
extension ApiResultX<T> on ApiResult<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  String? get error => isFailure ? (this as Failure<T>).error : null;

  // Handle result with callbacks
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).error);
    }
  }
}
```

### 4. Base Repository Pattern (data/repositories/base_repository.dart)

```dart
import '../../core/utils/api_result.dart';

abstract class BaseRepository {
  Future<ApiResult<T>> handleApiResult<T>(Future<ApiResult<T>> apiCall) async {
    try {
      return await apiCall;
    } catch (e) {
      return Failure('Repository error: ${e.toString()}');
    }
  }
}
```

## MVVM Pattern Implementation

### View (presentation/views/[feature]/[feature]_view.dart)

```dart
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '[feature]_viewmodel.dart';

class FeatureView extends StackedView<FeatureViewModel> {
  const FeatureView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    FeatureViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text('Feature')),
      body: viewModel.isBusy
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // UI components here
                if (viewModel.hasError)
                  Text('Error: ${viewModel.modelError}'),
                // Main content
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.items.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.items[index];
                      return ListTile(
                        title: Text(item.title),
                        onTap: () => viewModel.onItemTap(item),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.addItem,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  FeatureViewModel viewModelBuilder(BuildContext context) => FeatureViewModel();

  @override
  void onViewModelReady(FeatureViewModel viewModel) => viewModel.initialize();

  @override
  bool get reactive => true; // Rebuild on viewModel changes
}
```

### ViewModel (presentation/views/[feature]/[feature]_viewmodel.dart)

```dart
import 'package:stacked/stacked.dart';
import '../../../app/app_setup.dart';
import '../../../data/repositories/feature_repository.dart';
import '../../../data/models/feature_model.dart';
import '../../../core/utils/api_result.dart';

class FeatureViewModel extends BaseViewModel {
  // Dependencies
  final FeatureRepository _repository = locator<FeatureRepository>();

  // State
  List<FeatureModel> _items = [];
  String? _errorMessage;

  // Getters
  List<FeatureModel> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get hasData => _items.isNotEmpty;

  // Initialization
  Future<void> initialize() async {
    await loadItems();
  }

  // Business Logic
  Future<void> loadItems() async {
    setBusy(true);
    setError(null);

    final result = await _repository.getItems();
    result.when(
      success: (data) {
        _items = data;
        notifyListeners();
      },
      failure: (error) {
        setError(error);
      },
    );

    setBusy(false);
  }

  Future<void> addItem() async {
    setBusy(true);

    final result = await _repository.createItem();
    result.when(
      success: (newItem) {
        _items.add(newItem);
        notifyListeners();
      },
      failure: (error) {
        setError(error);
      },
    );

    setBusy(false);
  }

  void onItemTap(FeatureModel item) {
    // Handle item tap
    navigationService.navigateTo('/item/${item.id}');
  }

  Future<void> refresh() async {
    await loadItems();
  }
}
```

### Repository Implementation (data/repositories/[feature]_repository.dart)

```dart
import '../services/feature_api_service.dart';
import '../models/feature_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class FeatureRepository extends BaseRepository {
  final FeatureApiService _apiService = locator<FeatureApiService>();

  Future<ApiResult<List<FeatureModel>>> getItems() async {
    return handleApiResult(_apiService.getItems());
  }

  Future<ApiResult<FeatureModel>> getItemById(String id) async {
    return handleApiResult(_apiService.getItemById(id));
  }

  Future<ApiResult<FeatureModel>> createItem() async {
    return handleApiResult(_apiService.createItem());
  }

  Future<ApiResult<void>> deleteItem(String id) async {
    return handleApiResult(_apiService.deleteItem(id));
  }
}
```

### API Service (data/services/[feature]_api_service.dart)

```dart
import 'package:dio/dio.dart';
import '../models/feature_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'dio_service.dart';

class FeatureApiService {
  final DioService _dioService = locator<DioService>();

  Future<ApiResult<List<FeatureModel>>> getItems() async {
    try {
      final response = await _dioService.dio.get('/items');
      final items = (response.data as List)
          .map((json) => FeatureModel.fromJson(json))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(_handleDioError(e));
    } catch (e) {
      return Failure('Unexpected error: ${e.toString()}');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      default:
        return 'Network error';
    }
  }
}
```

## Setup Commands

1. **Create new Flutter project:**
```bash
flutter create project_name
cd project_name
```

2. **Add core dependencies:**
```bash
flutter pub add stacked stacked_services get_it dio connectivity_plus shared_preferences hive hive_flutter go_router json_annotation intl logger equatable
```

3. **Add Firebase:**
```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

4. **Add dev dependencies:**
```bash
flutter pub add -d build_runner hive_generator json_serializable flutter_lints
```

5. **Initialize Hive:**
```bash
flutter pub get
flutter packages pub run build_runner build
```

## Key Architecture Principles

### 1. **Separation of Concerns**
- **Views**: Only handle UI rendering and user interactions
- **ViewModels**: Handle business logic and state management
- **Repositories**: Handle data operations and caching
- **Services**: Handle external integrations (API, storage, etc.)

### 2. **Dependency Injection**
- Uses `get_it` service locator pattern
- All dependencies registered in `app_setup.dart`
- Services can be easily mocked for testing

### 3. **Reactive State Management**
- Uses Stacked's `BaseViewModel` with `notifyListeners()`
- Views automatically rebuild when ViewModel state changes
- Built-in busy/error state management

### 4. **Result Pattern**
- Custom `ApiResult<T>` wrapper for handling success/failure states
- Eliminates need for try-catch blocks in ViewModels
- Functional programming approach to error handling

### 5. **Repository Pattern**
- Abstracts data sources from business logic
- Easy to switch between local/remote data sources
- Centralized error handling in `BaseRepository`

## Benefits of This Architecture

- **Testable**: ViewModels can be unit tested independently
- **Maintainable**: Clear separation between UI and business logic
- **Scalable**: Easy to add new features following the same pattern
- **Readable**: Consistent structure across all features
- **Team-friendly**: Clear conventions for team development
- **Error Handling**: Centralized and consistent error handling
- **Performance**: Built-in caching and state management optimization

## Usage Guidelines

1. **Feature Development Flow:**
   - Create data model in `data/models/`
   - Implement API service in `data/services/`
   - Create repository in `data/repositories/`
   - Build ViewModel in `presentation/views/[feature]/`
   - Create View that extends `StackedView`

2. **State Management:**
   - Use `setBusy(true/false)` for loading states
   - Use `setError(message)` for error handling
   - Call `notifyListeners()` after state changes

3. **Navigation:**
   - Use `NavigationService` from service locator
   - Define routes in `core/constants/app_routes.dart`

4. **Dependencies:**
   - Register all services in `app_setup.dart`
   - Use `locator<T>()` to retrieve dependencies
   - Follow lazy singleton pattern for heavy services

This architecture provides a robust foundation for building scalable Flutter applications with clean separation of concerns and excellent testability.