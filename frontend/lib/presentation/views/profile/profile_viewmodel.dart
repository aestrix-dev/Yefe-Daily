import 'package:stacked/stacked.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/theme_service.dart';
import '../../../app/app_setup.dart';


class ProfileViewModel extends BaseViewModel {
  final _themeService = locator<ThemeService>();
  final _storageService = locator<StorageService>();

  // User data
  String _userName = 'John Doe';
  final String _avatarUrl = 'assets/images/avatar.png';
  bool _isPremium = false;
  bool _showUpgrade = false;
  bool _isNotificationsEnabled = true;

  // Getters
  String get userName => _userName;
  String get avatarUrl => _avatarUrl;
  bool get isPremium => _isPremium;
  bool get showUpgrade => _showUpgrade;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isDarkMode => _themeService.isDarkMode;

  String get userPlan => _isPremium ? 'Yefa +' : 'Free plan';

  void onModelReady() {
    _loadUserData();
  }

  void _loadUserData() {
    // Load user data from storage or API
    _isPremium = _storageService.getBool('isPremium') ?? false;
    _isNotificationsEnabled =
        _storageService.getBool('isNotificationsEnabled') ?? true;
    _userName = _storageService.getString('userName') ?? 'John Doe';

    notifyListeners();
  }

  void showUpgradeCard() {
    // This method will now be used to trigger the popup
    // The actual popup showing will be handled in the view
    notifyListeners();
  }

  void upgradeToPremium() {
    _isPremium = true;
    _showUpgrade = false;

    // Save to storage
    _storageService.setBool('isPremium', true);

    print('=== UPGRADED TO PREMIUM ===');
    print('User: $_userName');
    print('New Plan: ${userPlan}');
    print('=========================');

    notifyListeners();
  }

  void toggleTheme() {
    _themeService.toggleTheme();
    notifyListeners();
  }

  void toggleNotifications() {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    _storageService.setBool('isNotificationsEnabled', _isNotificationsEnabled);

    print('=== NOTIFICATIONS TOGGLED ===');
    print('Notifications enabled: $_isNotificationsEnabled');
    print('============================');

    notifyListeners();
  }

  void navigateToVerseLanguage() {
    print('Navigate to Verse Language settings');
    // TODO: Implement navigation to verse language selection
  }

  void navigateToYefaManCave() {
    print('Navigate to Yefa Man Cave WhatsApp group');
    // TODO: Implement WhatsApp group navigation
  }

  void navigateToTowelTalk() {
    print('Navigate to Towel Talk');
    // TODO: Implement Towel Talk navigation
  }
}
