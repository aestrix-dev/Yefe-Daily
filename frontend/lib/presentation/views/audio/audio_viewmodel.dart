import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/audio_model.dart';
import 'package:yefa/data/services/audio_api_service.dart';
import 'package:yefa/data/services/audio_download_service.dart';
import 'package:yefa/data/services/audio_player_service.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/cache/audio_cache.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'package:yefa/data/repositories/payment_repository.dart';
import 'package:yefa/presentation/shared/widgets/payment_provider_sheet.dart';
import 'package:yefa/presentation/shared/widgets/toast_overlay.dart';
import 'package:yefa/presentation/views/audio/widgets/audio_player_dialog.dart';

class AudioViewModel extends BaseViewModel {
  final AudioApiService _audioApiService = locator<AudioApiService>();
  final AudioDownloadService _downloadService = locator<AudioDownloadService>();
  final AudioPlayerService _playerService = locator<AudioPlayerService>();
  final StorageService _storageService = locator<StorageService>();
  final PaymentService _paymentService = locator<PaymentService>();
  final PaymentRepository _paymentRepository = locator<PaymentRepository>();

  List<AudioCategoryModel> _audioCategories = [];
  String? _showUpgradeCardForCategory;
  bool _isPremiumUser = false;
  bool _isLoading = false;
  bool _hasInternetConnection = true;
  String? _errorMessage;
  final Map<String, bool> _downloadingStates = {};
  final Map<String, double> _downloadProgress = {};

  // Getters
  List<AudioCategoryModel> get audioCategories => _audioCategories;
  String? get showUpgradeCardForCategory => _showUpgradeCardForCategory;
  bool get isPremiumUser => _isPremiumUser;
  bool get isLoading => _isLoading;
  bool get hasInternetConnection => _hasInternetConnection;
  String? get errorMessage => _errorMessage;
  AudioPlayerService get playerService => _playerService;

  BuildContext? _context;
  bool contextAlreadySet = false;
  bool _isInitialized = false;

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
    }
  }

  Future<void> onModelReady() async {
    // Only initialize once to prevent interrupting audio playback
    if (!_isInitialized) {
      await _initializeServices();
      _isInitialized = true;
    } else {
      // Just refresh the UI state without disrupting audio
      await _refreshUIStateOnly();
    }
  }

  Future<void> _initializeServices() async {
    await _playerService.initialize();

    // Load premium status
    await _loadPremiumStatus();

    // Check for premium status updates from notifications
    await _checkForPremiumStatusUpdates();

    // Load cached data first, then fetch fresh data
    await _loadCachedAudios();
    await _loadFreshDataIfOnline();
  }

  Future<void> _refreshUIStateOnly() async {
    // Only refresh premium status (lightweight operation)
    await _loadPremiumStatus();
    await _checkForPremiumStatusUpdates();
    
    // Load cached data if we don't have any (but don't fetch fresh data)
    if (_audioCategories.isEmpty) {
      await _loadCachedAudios();
      // Only fetch fresh data if we truly have no data
      await _loadFreshDataIfNeeded();
    }
  }

  Future<void> _loadCachedAudios() async {
    try {
      final cachedAudios = await _storageService.getCachedAudioList();
      if (cachedAudios != null && cachedAudios.isNotEmpty) {
        _createSingleCategory(cachedAudios);
      }
    } catch (e) {
      print('❌ Error loading cached audios: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      _isPremiumUser = await _paymentService.isUserPremium();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading premium status: $e');
      _isPremiumUser = false;
    }
  }

  /// Check if premium status was updated from payment notifications
  Future<void> _checkForPremiumStatusUpdates() async {
    try {
      final wasUpdated = _storageService.getBool('premium_status_updated') ?? false;

      if (wasUpdated) {
        print('👑 Premium status was updated from notification in AudioView, refreshing...');

        // Clear the update flag
        await _storageService.remove('premium_status_updated');

        // Get the update type
        final updateType = _storageService.getString('premium_update_type') ?? 'unknown';
        await _storageService.remove('premium_update_type');

        // Reload premium status
        await _loadPremiumStatus();

        // Show appropriate message to user if context is available
        if (_context != null) {
          if (updateType == 'success') {
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Welcome to Yefa Plus! Enjoy unlimited audio content 🎵👑',
            );
          } else if (updateType == 'failed') {
            ToastOverlay.showError(
              context: _context!,
              message: 'Payment failed. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error checking premium status updates in AudioView: $e');
    }
  }

  Future<void> _loadFreshDataIfOnline() async {
    try {
      _hasInternetConnection = await _checkInternetConnection();

      if (_hasInternetConnection) {
        print('🎵 Fetching fresh audio data...');
        await fetchAudios(fromCache: false);
      } else {
        // Still try to fetch - sometimes connectivity check fails but internet works
        await fetchAudios(fromCache: false);
      }
    } catch (e) {
      print('❌ Error loading fresh data: $e');
      _hasInternetConnection = false;
    }
  }

  // Lightweight data refresh for when returning to screen - only fetch if we have no data
  Future<void> _loadFreshDataIfNeeded() async {
    // Only fetch fresh data if we have no cached data loaded
    if (_audioCategories.isEmpty) {
      await _loadFreshDataIfOnline();
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;
      print(
        '🔍 Connectivity check result: $connectivityResult (hasConnection: $hasConnection)',
      );
      return hasConnection;
    } catch (e) {
      print('❌ Connectivity check failed: $e');
      return false;
    }
  }

  // Fetch audios from API
  Future<void> fetchAudios({bool fromCache = true}) async {
    print('🎵 AudioViewModel: Starting to fetch audios...');

    // Only show loading if we don't have cached data
    if (_audioCategories.isEmpty) {
      _setLoading(true);
    }

    _setErrorMessage(null);

    try {
      final result = await _audioApiService.getAudios();
      print('🎵 AudioViewModel: API call completed');

      if (result is Success<List<AudioModel>>) {
        print('🎵 AudioViewModel: Success! Got ${result.data.length} audios');

        // Cache the fresh data
        await _storageService.cacheAudioList(result.data);

        _createSingleCategory(result.data);
      } else if (result is Failure) {
        print('❌ AudioViewModel: API failure - ${result.error}');

        // Only set error if we don't have cached data
        if (_audioCategories.isEmpty) {
          _setErrorMessage(result.error);
        }
      }
    } catch (e) {
      print('❌ AudioViewModel: Exception during fetch - $e');

      // Only set error if we don't have cached data
      if (_audioCategories.isEmpty) {
        _setErrorMessage('Failed to fetch audios: $e');
      }
    } finally {
      _setLoading(false);
      print('🎵 AudioViewModel: Fetch completed, loading set to false');
    }
  }

  // Create single "Tower Talk" category with all audios
  void _createSingleCategory(List<AudioModel> audios) {
    print(
      '🎵 AudioViewModel: Creating single category with ${audios.length} audios',
    );
    _audioCategories = [
      AudioCategoryModel(id: 'tower_talk', title: 'Tower Talk', audios: audios),
    ];
    notifyListeners();
    print('🎵 AudioViewModel: Category created and listeners notified');
  }

  // Handle audio tap - shows bottom sheet or upgrade card
  void handleAudioTap(AudioModel audio) {
    if (audio.isPremium && !_isPremiumUser) {
      toggleUpgradeCard('tower_talk');
    } else {
      if (_context != null) {
        _showAudioPlayer(_context!, audio);
      }
    }
  }

  void _showAudioPlayer(BuildContext context, AudioModel audio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 10,
      builder: (context) => AudioPlayerBottomSheet(
        audio: audio,
        playerService: _playerService,
        onClose: () {
          Navigator.of(context).pop();
        },
        onPlayTap: () {
          _handlePlayTap(audio);
        },
        onPreviousTap: () {
          _handlePreviousTap();
        },
        onNextTap: () {
          _handleNextTap();
        },
        onSeekForward: () {
          _playerService.seekForwardTenSeconds();
        },
        onSeekBackward: () {
          _playerService.seekBackwardTenSeconds();
        },
      ),
    );
  }

  // Handle play button tap in bottom sheet
  Future<void> _handlePlayTap(AudioModel audio) async {
    try {
      // Check if already downloaded
      if (await _downloadService.isAudioDownloaded(audio.id)) {
        final localPath = _downloadService.getLocalPath(audio.id);
        if (localPath != null) {
          await _playAudio(audio, localPath);
          return;
        }
      }

      await _downloadAndPlay(audio);
    } catch (e) {
      print('❌ Error playing audio: $e');
      _setErrorMessage('Failed to play audio: $e');
    }
  }

  Future<void> _downloadAndPlay(AudioModel audio) async {
    print('🎧 Downloading: ${audio.title}');
    _downloadingStates[audio.id] = true;
    notifyListeners();

    try {
      final localPath = await _downloadService.downloadAudio(
        audio.id,
        audio.downloadUrl,
        onProgress: (progress) {
          _downloadProgress[audio.id] = progress;
          notifyListeners();
        },
      );

      _downloadingStates[audio.id] = false;
      _downloadProgress.remove(audio.id);
      notifyListeners();

      // Play the downloaded audio
      await _playAudio(audio, localPath);
    } catch (e) {
      print('❌ Download error: $e');
      _downloadingStates[audio.id] = false;
      _downloadProgress.remove(audio.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _playAudio(AudioModel audio, String localPath) async {
    try {
      // Get all audios for playlist
      final allAudios = _audioCategories.first.audios;
      final audioIndex = allAudios.indexWhere((a) => a.id == audio.id);

      await _playerService.setPlaylistAndPlay(allAudios, audioIndex, localPath);
    } catch (e) {
      print('❌ Playback error: $e');
      rethrow;
    }
  }

  // Handle previous button in bottom sheet
  Future<void> _handlePreviousTap() async {
    if (_playerService.hasPrevious) {
      await _playerService.playPrevious();
      await _ensureCurrentAudioIsDownloaded();
    }
  }

  // Handle next button in bottom sheet
  Future<void> _handleNextTap() async {
    if (_playerService.hasNext) {
      await _playerService.playNext();
      await _ensureCurrentAudioIsDownloaded();
    }
  }

  // Ensure current audio is downloaded when switching tracks
  Future<void> _ensureCurrentAudioIsDownloaded() async {
    print('🎵 AudioViewModel: Ensuring current audio is downloaded...');
    final currentAudio = _playerService.currentAudio;
    if (currentAudio == null) {
      print('❌ AudioViewModel: Current audio is null');
      return;
    }

    print('🎵 AudioViewModel: Current audio: ${currentAudio.title}');
    try {
      if (!(await _downloadService.isAudioDownloaded(currentAudio.id))) {
        print(
          '🎵 AudioViewModel: Current audio not downloaded, downloading...',
        );
        final localPath = await _downloadService.downloadAudio(
          currentAudio.id,
          currentAudio.downloadUrl,
        );
        print('🎵 AudioViewModel: Download completed, setting up playback...');
        await _playerService.setPlaylistAndPlay(
          _playerService.currentPlaylist,
          _playerService.currentPlaylistIndex,
          localPath,
        );
      } else {
        print('🎵 AudioViewModel: Current audio already downloaded');
        final localPath = _downloadService.getLocalPath(currentAudio.id);
        if (localPath != null) {
          print('🎵 AudioViewModel: Setting up playback with existing file...');
          await _playerService.setPlaylistAndPlay(
            _playerService.currentPlaylist,
            _playerService.currentPlaylistIndex,
            localPath,
          );
        } else {
          print('❌ AudioViewModel: Local path is null for downloaded audio');
        }
      }
    } catch (e) {
      print('❌ AudioViewModel: Error in _ensureCurrentAudioIsDownloaded - $e');
      _setErrorMessage('Failed to switch track: $e');
    }
  }

  // Check if audio is downloaded
  Future<bool> isAudioDownloaded(String audioId) async {
    final isDownloaded = await _downloadService.isAudioDownloaded(audioId);
    print('🎵 AudioViewModel: Audio $audioId downloaded: $isDownloaded');
    return isDownloaded;
  }

  // Check if audio is currently downloading
  bool isAudioDownloading(String audioId) {
    final isDownloading = _downloadingStates[audioId] ?? false;
    print('🎵 AudioViewModel: Audio $audioId downloading: $isDownloading');
    return isDownloading;
  }

  // Get download progress
  double getDownloadProgress(String audioId) {
    final progress = _downloadProgress[audioId] ?? 0.0;
    return progress;
  }

  void showPaymentSheet() {
    print('🎵 AudioViewModel: Showing payment sheet');
    if (_context == null) {
      print('❌ AudioViewModel: Context is null, cannot show payment sheet');
      return;
    }

    showModalBottomSheet(
      context: _context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentProviderSheet(
        onStripeTap: () async {
          Navigator.of(context).pop();
          print('🎵 AudioViewModel: Stripe payment selected');
          await _handleStripePayment();
        },
        onPaystackTap: () async {
          Navigator.of(context).pop();
          print('🎵 AudioViewModel: Paystack payment selected');
          await _handlePaystackPayment();
        },
      ),
    );
  }

  Future<void> _handleStripePayment() async {
    if (_context == null) return;

    try {
      print('💳 AudioViewModel: Processing Stripe payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'stripe',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        print('✅ AudioViewModel: Stripe payment successful!');
        await _handleSuccessfulPayment();
      } else {
        print('❌ AudioViewModel: Stripe payment failed: ${result.error}');
        ToastOverlay.showError(
          context: _context!,
          message: result.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }

      print('❌ AudioViewModel: Stripe payment error: $e');
      ToastOverlay.showError(context: _context!, message: 'Payment failed: $e');
    }
  }

  Future<void> _handlePaystackPayment() async {
    if (_context == null) return;

    try {
      print('💳 AudioViewModel: Processing Paystack payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'paystack',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        print('✅ AudioViewModel: Paystack payment successful!');
        await _handleSuccessfulPayment();
      } else {
        print('❌ AudioViewModel: Paystack payment failed: ${result.error}');
        ToastOverlay.showError(
          context: _context!,
          message: result.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }

      print('❌ AudioViewModel: Paystack payment error: $e');
      ToastOverlay.showError(context: _context!, message: 'Payment failed: $e');
    }
  }

  Future<void> _handleSuccessfulPayment() async {
    try {
      // Update premium status in storage
      await _paymentService.updateUserPremiumStatus();
      
      // Update local premium status
      _isPremiumUser = true;
      _showUpgradeCardForCategory = null;
      
      print('✅ AudioViewModel: Premium status updated successfully');
      notifyListeners();

      // Show success message
      if (_context != null) {
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Welcome to Yefa Plus! 🎉👑',
        );
      }
    } catch (e) {
      print('❌ AudioViewModel: Error updating premium status: $e');
      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'Payment successful but failed to update status',
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    if (_context == null) return;
    
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void toggleUpgradeCard(String categoryId) {
    print('🎵 AudioViewModel: Toggling upgrade card for category: $categoryId');
    if (_showUpgradeCardForCategory == categoryId) {
      _showUpgradeCardForCategory = null;
      print('🎵 AudioViewModel: Hiding upgrade card');
    } else {
      _showUpgradeCardForCategory = categoryId;
      print('🎵 AudioViewModel: Showing upgrade card');
    }
    notifyListeners();
  }

  void upgradeToPremium() {
    print('🎵 AudioViewModel: Upgrading to premium - showing payment sheet');
    showPaymentSheet();
  }

  // Refresh data (pull-to-refresh)
  Future<void> refresh() async {
    print('🎵 AudioViewModel: Refreshing data...');
    // Reload premium status and fresh data on manual refresh
    // Note: This does NOT re-initialize the player service to avoid disrupting playback
    await _loadPremiumStatus();
    await fetchAudios(fromCache: false);
  }

  void _setLoading(bool loading) {
    print('🎵 AudioViewModel: Setting loading to $loading');
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? errorMessage) {
    print('🎵 AudioViewModel: Setting error message: $errorMessage');
    _errorMessage = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    print(
      '🎵 AudioViewModel: Dispose called - NOT disposing singleton services',
    );
    // Don't dispose singleton services
    super.dispose();
  }
}
