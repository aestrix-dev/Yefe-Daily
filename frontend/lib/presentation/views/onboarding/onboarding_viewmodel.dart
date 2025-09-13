import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:go_router/go_router.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/auth_model.dart';

import '../../../app/app_setup.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/firebase_notification_service.dart';

class OnboardingViewModel extends BaseViewModel {
  final _storageService = locator<StorageService>();
  final _authRepository = locator<AuthRepository>();
  final _fcmService = FirebaseNotificationService();

  final PageController pageController = PageController();
  int _currentIndex = 0;
  bool _isAuthenticating = false;
  String? _errorMessage;

  // User data from onboarding pages
  String _email = '';
  String _name = '';
  String _password = 'Password@123';
  String _confirmPassword = 'Password@123';
  String _selectedLanguage = 'English';
  bool _morningPrompt = true;
  bool _eveningReflection = true;
  bool _challenge = false;
  String _morningReminder = '08:00';
  String _eveningReminder = '12:00';

  // Getters
  int get currentIndex => _currentIndex;
  bool get isLastPage => _currentIndex == 2;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;

  // User data getters
  String get email => _email;
  String get name => _name;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get selectedLanguage => _selectedLanguage;
  bool get morningPrompt => _morningPrompt;
  bool get eveningReflection => _eveningReflection;
  bool get challenge => _challenge;
  String get morningReminder => _morningReminder;
  String get eveningReminder => _eveningReminder;

  // User data setters
  void setEmail(String value) {
    _email = value;
    _clearError();
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _clearError();
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _clearError();
    notifyListeners();
  }

  void setSelectedLanguage(String value) {
    _selectedLanguage = value;
    notifyListeners();
  }

  void setMorningPrompt(bool value) {
    _morningPrompt = value;
    notifyListeners();
  }

  void setEveningReflection(bool value) {
    _eveningReflection = value;
    notifyListeners();
  }

  void setChallenge(bool value) {
    _challenge = value;
    notifyListeners();
  }

  void setMorningReminder(String value) {
    _morningReminder = value;
    notifyListeners();
  }

  void setEveningReminder(String value) {
    _eveningReminder = value;
    notifyListeners();
  }

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

  void previousPage() {
    if (_currentIndex > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // New method to handle authentication and registration
  Future<void> authenticateAndComplete(BuildContext context) async {
    // Validate inputs first
    if (!_validateInputs()) return;

    _setAuthenticating(true);
    _clearError();

    try {
      // Create user preferences
      final userPrefs = UserPreferences(
        morningPrompt: _morningPrompt,
        eveningReflection: _eveningReflection,
        challenge: _challenge,
        language: _selectedLanguage,
        reminders: ReminderSettings(
          morningReminder: _morningReminder,
          eveningReminder: _eveningReminder,
        ),
      );

      // Create register request
      final request = RegisterRequest(
        email: _email,
        name: _name,
        password: _password,
        confirmPassword: _confirmPassword,
        userPrefs: userPrefs,
      );

      print('OnboardingViewModel: Starting registration...');

      // Make the registration API call
      final result = await _authRepository.register(request);

      if (result.isSuccess) {
        print('OnboardingViewModel: Registration successful');

        // Mark onboarding as completed
        await _storageService.setBool('hasSeenOnboarding', true);

        // Submit FCM token after successful registration
        print('OnboardingViewModel: Submitting FCM token...');
        try {
          bool fcmSuccess = await _fcmService.submitTokenToServer();
          if (fcmSuccess) {
            print('✅ OnboardingViewModel: FCM token submitted successfully');
          } else {
            print('⚠️ OnboardingViewModel: FCM token submission failed');
          }
        } catch (e) {
          print('❌ OnboardingViewModel: FCM token error: $e');
        }

        _setAuthenticating(false);

        // Navigate to home
        final context = StackedService.navigatorKey?.currentContext;
        if (context != null) {
          print('OnboardingViewModel: Navigating to home');
          context.pushReplacement(AppRoutes.home);
        } else {
          print('OnboardingViewModel: ERROR - Context is null!');
        }
      } else {
        // Registration failed
        print('OnboardingViewModel: Registration failed - ${result.error}');
        _setError(result.error ?? 'Registration failed. Please try again.');
        _setAuthenticating(false);
      }
    } catch (e) {
      print('OnboardingViewModel: Registration error - $e');
      _setError('An unexpected error occurred. Please try again.');
      _setAuthenticating(false);
    }
  }

  // Validation method
  bool _validateInputs() {
    if (_email.isEmpty ||
        _name.isEmpty ||
        _password.isEmpty ||
        _confirmPassword.isEmpty) {
      _setError('Please fill in all required fields');
      return false;
    }

    if (!_isValidEmail(_email)) {
      _setError('Please enter a valid email address');
      return false;
    }

    if (_password.length < 8) {
      _setError('Password must be at least 8 characters long');
      return false;
    }

    if (_password != _confirmPassword) {
      _setError('Passwords do not match');
      return false;
    }

    if (_selectedLanguage == 'Select language') {
      _setError('Please select a language');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _setAuthenticating(bool value) {
    _isAuthenticating = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Legacy method - keeping for compatibility but now calls the new method
  void completeOnboarding(BuildContext context) {
    authenticateAndComplete(context);
  }

  // Method to check if page 2 data is valid for navigation
  bool canProceedFromPageTwo() {
    return _email.isNotEmpty &&
        _name.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _selectedLanguage != 'Select language';
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
