import 'package:stacked/stacked.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/theme_service.dart';

class ProfileViewModel extends BaseViewModel {
  final _themeService = locator<ThemeService>();
  final _storageService = locator<StorageService>();

  // User data
  String _userName = 'Guest';
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

  Future<void> _loadUserData() async {
    final user = await _storageService.getUser();
    _userName = user?.name ?? 'Guest';

    _isPremium = _storageService.getBool('isPremium') ?? false;
    _isNotificationsEnabled =
        _storageService.getBool('isNotificationsEnabled') ?? true;

    print('👤 User loaded: $_userName');
    notifyListeners();
  }

  void showUpgradeCard() {
    notifyListeners();
  }

  void upgradeToPremium() {
    _isPremium = true;
    _showUpgrade = false;
    _storageService.setBool('isPremium', true);

    print('=== UPGRADED TO PREMIUM ===');
    print('User: $_userName');
    print('New Plan: $userPlan');
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
    // TODO: Implement navigation
  }

  void navigateToYefaManCave() {
    print('Navigate to WhatsApp group');
    // TODO: Implement navigation
  }

  void navigateToTowelTalk() {
    print('Navigate to Towel Talk');
    // TODO: Implement navigation
  }
}
