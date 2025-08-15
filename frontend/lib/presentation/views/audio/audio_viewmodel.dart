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
import 'package:yefa/presentation/shared/widgets/payment_provider_sheet.dart';
import 'package:yefa/presentation/views/audio/widgets/audio_player_dialog.dart';

class AudioViewModel extends BaseViewModel {
  final AudioApiService _audioApiService = locator<AudioApiService>();
  final AudioDownloadService _downloadService = locator<AudioDownloadService>();
  final AudioPlayerService _playerService = locator<AudioPlayerService>();
  final StorageService _storageService = locator<StorageService>();

  List<AudioCategoryModel> _audioCategories = [];
  String? _showUpgradeCardForCategory;
  bool _isPremiumUser = false;
  bool _isLoading = false;
  bool _hasInternetConnection = true;
  String? _errorMessage;
  Map<String, bool> _downloadingStates = {};
  Map<String, double> _downloadProgress = {};

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

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
      print('🎵 AudioViewModel: Context set');
    }
  }

  Future<void> onModelReady() async {
    print('🎵 AudioViewModel: Model ready, initializing services...');
    await _playerService.initialize();
    print('🎵 AudioViewModel: Player service initialized');

    // Load cached data first, then fetch fresh data
    await _loadCachedAudios();
    await _loadFreshDataIfOnline();
  }

  Future<void> _loadCachedAudios() async {
    try {
      final cachedAudios = await _storageService.getCachedAudioList();
      if (cachedAudios != null && cachedAudios.isNotEmpty) {
        _createSingleCategory(cachedAudios);
        print('✅ Loaded ${cachedAudios.length} cached audios');
      }
    } catch (e) {
      print('❌ Error loading cached audios: $e');
    }
  }

  Future<void> _loadFreshDataIfOnline() async {
    try {
      _hasInternetConnection = await _checkInternetConnection();

      if (_hasInternetConnection) {
        print('🌐 Internet connection available, fetching fresh data...');
        await fetchAudios(fromCache: false);
      } else {
        print('📱 No internet connection detected');
        // Still try to fetch - sometimes connectivity check fails but internet works
        print('🔄 Attempting to fetch data anyway...');
        await fetchAudios(fromCache: false);
      }
    } catch (e) {
      print('❌ Error loading fresh data: $e');
      _hasInternetConnection = false;
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
    print('🎵 AudioViewModel: Audio tapped - ${audio.title}');
    print(
      '🎵 AudioViewModel: isPremium: ${audio.isPremium}, isPremiumUser: $_isPremiumUser',
    );

    if (audio.isPremium && !_isPremiumUser) {
      print('🎵 AudioViewModel: Showing upgrade card for premium audio');
      toggleUpgradeCard('tower_talk');
    } else {
      print(
        '🎵 AudioViewModel: Showing audio player for ${audio.isPremium ? "premium" : "free"} audio',
      );
      if (_context != null) {
        _showAudioPlayer(_context!, audio);
      } else {
        print('❌ AudioViewModel: Context is null, cannot show audio player');
      }
    }
  }

  void _showAudioPlayer(BuildContext context, AudioModel audio) {
    print('🎵 AudioViewModel: Opening bottom sheet for ${audio.title}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 10,
      builder: (context) => AudioPlayerBottomSheet(
        audio: audio,
        playerService: _playerService,
        onClose: () {
          print('🎵 AudioViewModel: Bottom sheet closed');
          Navigator.of(context).pop();
        },
        onPlayTap: () {
          print('🎵 AudioViewModel: Play button tapped');
          _handlePlayTap(audio);
        },
        onPreviousTap: () {
          print('🎵 AudioViewModel: Previous button tapped');
          _handlePreviousTap();
        },
        onNextTap: () {
          print('🎵 AudioViewModel: Next button tapped');
          _handleNextTap();
        },
        onSeekForward: () {
          print('🎵 AudioViewModel: Seek forward tapped');
          _playerService.seekForwardTenSeconds();
        },
        onSeekBackward: () {
          print('🎵 AudioViewModel: Seek backward tapped');
          _playerService.seekBackwardTenSeconds();
        },
      ),
    );
  }

  // Handle play button tap in bottom sheet
  Future<void> _handlePlayTap(AudioModel audio) async {
    print('🎵 AudioViewModel: Handling play tap for ${audio.title}');
    try {
      // Check if already downloaded
      print('🎵 AudioViewModel: Checking if audio is downloaded...');
      if (await _downloadService.isAudioDownloaded(audio.id)) {
        print(
          '🎵 AudioViewModel: Audio already downloaded, getting local path...',
        );
        final localPath = _downloadService.getLocalPath(audio.id);
        if (localPath != null) {
          print('🎵 AudioViewModel: Local path found: $localPath');
          await _playAudio(audio, localPath);
          return;
        } else {
          print(
            '❌ AudioViewModel: Local path is null despite audio being downloaded',
          );
        }
      }

      print(
        '🎵 AudioViewModel: Audio not downloaded, starting download and play...',
      );
      await _downloadAndPlay(audio);
    } catch (e) {
      print('❌ AudioViewModel: Error in _handlePlayTap - $e');
      _setErrorMessage('Failed to play audio: $e');
    }
  }

  Future<void> _downloadAndPlay(AudioModel audio) async {
    print('🎵 AudioViewModel: Starting download for ${audio.title}');
    _downloadingStates[audio.id] = true;
    notifyListeners();

    try {
      print('🎵 AudioViewModel: Calling download service...');
      final localPath = await _downloadService.downloadAudio(
        audio.id,
        audio.downloadUrl,
        onProgress: (progress) {
          print(
            '🎵 AudioViewModel: Download progress: ${(progress * 100).toInt()}%',
          );
          _downloadProgress[audio.id] = progress;
          notifyListeners();
        },
      );

      print('🎵 AudioViewModel: Download completed, local path: $localPath');
      _downloadingStates[audio.id] = false;
      _downloadProgress.remove(audio.id);
      notifyListeners();

      // Play the downloaded audio
      print('🎵 AudioViewModel: Starting playback...');
      await _playAudio(audio, localPath);
    } catch (e) {
      print('❌ AudioViewModel: Error in _downloadAndPlay - $e');
      _downloadingStates[audio.id] = false;
      _downloadProgress.remove(audio.id);
      notifyListeners();
      throw e;
    }
  }

  Future<void> _playAudio(AudioModel audio, String localPath) async {
    print('🎵 AudioViewModel: Setting up playlist and playing audio...');
    try {
      // Get all audios for playlist
      final allAudios = _audioCategories.first.audios;
      final audioIndex = allAudios.indexWhere((a) => a.id == audio.id);
      print(
        '🎵 AudioViewModel: Audio index in playlist: $audioIndex of ${allAudios.length}',
      );

      print('🎵 AudioViewModel: Calling player service setPlaylistAndPlay...');
      await _playerService.setPlaylistAndPlay(allAudios, audioIndex, localPath);
      print('🎵 AudioViewModel: Playback started successfully');
    } catch (e) {
      print('❌ AudioViewModel: Error in _playAudio - $e');
      throw e;
    }
  }

  // Handle previous button in bottom sheet
  Future<void> _handlePreviousTap() async {
    print('🎵 AudioViewModel: Handling previous tap');
    if (_playerService.hasPrevious) {
      print('🎵 AudioViewModel: Has previous track, switching...');
      await _playerService.playPrevious();
      await _ensureCurrentAudioIsDownloaded();
    } else {
      print('🎵 AudioViewModel: No previous track available');
    }
  }

  // Handle next button in bottom sheet
  Future<void> _handleNextTap() async {
    print('🎵 AudioViewModel: Handling next tap');
    if (_playerService.hasNext) {
      print('🎵 AudioViewModel: Has next track, switching...');
      await _playerService.playNext();
      await _ensureCurrentAudioIsDownloaded();
    } else {
      print('🎵 AudioViewModel: No next track available');
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
        onStripeTap: () {
          print('🎵 AudioViewModel: Stripe payment selected');
          Navigator.of(context).pop();
          // TODO: implement Stripe payment logic
          // After successful payment, call upgradeToPremium()
        },
        onPaystackTap: () {
          print('🎵 AudioViewModel: Paystack payment selected');
          Navigator.of(context).pop();
          // TODO: implement Paystack payment logic
          // After successful payment, call upgradeToPremium()
        },
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
    print('🎵 AudioViewModel: Upgrading to premium');
    _isPremiumUser = true;
    _showUpgradeCardForCategory = null;

    print('=== UPGRADED TO PREMIUM ===');
    print('User now has access to all premium audio content');
    print('=========================');

    // TODO: Update your storage service here
    // storageService.setIsPremium(true);

    notifyListeners();
  }

  // Refresh data (pull-to-refresh)
  Future<void> refresh() async {
    print('🎵 AudioViewModel: Refreshing data...');
    // Always try to fetch fresh data on manual refresh
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
