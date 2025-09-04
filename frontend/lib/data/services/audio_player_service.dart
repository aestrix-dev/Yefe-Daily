import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';
import '../models/audio_model.dart';

class AudioPlayerService extends BaseAudioHandler {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<List<AudioModel>> _playlistSubject =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndexSubject = BehaviorSubject.seeded(0);
  bool _isInitialized = false;
  final Logger _logger = Logger();

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Stream<List<AudioModel>> get playlist => _playlistSubject.stream;
  Stream<int> get currentIndex => _currentIndexSubject.stream;
  List<AudioModel> get currentPlaylist => _playlistSubject.value;
  int get currentPlaylistIndex => _currentIndexSubject.value;
  AudioModel? get currentAudio =>
      currentPlaylist.isEmpty ? null : currentPlaylist[currentPlaylistIndex];

  // Check if there's a next track
  bool get hasNext => currentPlaylistIndex < currentPlaylist.length - 1;

  // Check if there's a previous track
  bool get hasPrevious => currentPlaylistIndex > 0;

  Future<void> initialize() async {
    // Only initialize once to prevent disrupting ongoing playback
    if (_isInitialized) {
      return;
    }

    // Note: App icon will be automatically used by the system for media controls

    // Set up audio session for background play
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));

    // Listen to player state changes for enhanced notification controls
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final hasPlaylist = currentPlaylist.isNotEmpty;

      // Enhanced controls for notification and lock screen
      final controls = <MediaControl>[
        // Previous track (only if there's a previous track)
        if (hasPlaylist && hasPrevious) MediaControl.skipToPrevious,
        
        // Play/Pause - always available
        if (isPlaying) MediaControl.pause else MediaControl.play,
        
        // Next track (only if there's a next track)
        if (hasPlaylist && hasNext) MediaControl.skipToNext,
        
        // Additional controls for richer experience
        MediaControl.stop,
      ];

      // Update playback state for enhanced system media controls
      playbackState.add(
        playbackState.value.copyWith(
          controls: controls,
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.setSpeed,
            MediaAction.stop,
          },
          androidCompactActionIndices: const [0, 1, 2], // Show first 3 controls in compact view
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[processingState]!,
          playing: isPlaying,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: hasPlaylist ? currentPlaylistIndex : null,
        ),
      );
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    _isInitialized = true;
  }

  // Set playlist and play specific audio
  Future<void> setPlaylistAndPlay(
    List<AudioModel> playlist,
    int index,
    String localFilePath,
  ) async {
    try {
      _playlistSubject.add(playlist);
      _currentIndexSubject.add(index);

      // Update media item for system controls with enhanced metadata
      final audio = playlist[index];
      final mediaItemData = _createMediaItem(audio);
      mediaItem.add(mediaItemData);

      // Set audio source and play
      await _audioPlayer.setFilePath(localFilePath);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  // Toggle Play/Pause
  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  // Play next track (enhanced for notification controls)
  Future<void> playNext() async {
    if (hasNext) {
      final nextIndex = currentPlaylistIndex + 1;
      final nextAudio = currentPlaylist[nextIndex];
      
      _currentIndexSubject.add(nextIndex);
      
      // Update media item for the new track
      final mediaItemData = _createMediaItem(nextAudio);
      mediaItem.add(mediaItemData);
    }
  }

  // Play previous track (enhanced for notification controls)
  Future<void> playPrevious() async {
    if (hasPrevious) {
      final prevIndex = currentPlaylistIndex - 1;
      final prevAudio = currentPlaylist[prevIndex];
      
      _currentIndexSubject.add(prevIndex);
      
      // Update media item for the previous track
      final mediaItemData = _createMediaItem(prevAudio);
      mediaItem.add(mediaItemData);
    }
  }

  // Custom seek methods for UI buttons
  Future<void> seekForwardTenSeconds() async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final duration = _audioPlayer.duration;
    if (duration != null && newPosition < duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  Future<void> seekBackwardTenSeconds() async {
    final currentPosition = _audioPlayer.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  // Stop and clear
  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _playlistSubject.add([]);
    _currentIndexSubject.add(0);
  }

  // Audio Service handlers - these override BaseAudioHandler methods
  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> skipToNext() => playNext();

  @override
  Future<void> skipToPrevious() => playPrevious();

  @override
  Future<void> seekForward(bool begin) async {
    if (begin) {
      await seekForwardTenSeconds();
    }
  }

  @override
  Future<void> seekBackward(bool begin) async {
    if (begin) {
      await seekBackwardTenSeconds();
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _playlistSubject.add([]);
    _currentIndexSubject.add(0);
    
    // Clear media item
    mediaItem.add(null);
    
    // Update playback state to stopped
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
      controls: [],
    ));
    
    return super.stop();
  }

  // Additional system control handlers
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    // Handle repeat mode changes from system controls
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.group:
        await _audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
    
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    // Handle shuffle mode changes from system controls
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await _audioPlayer.setShuffleModeEnabled(enabled);
    
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  // Enhanced queue management for system controls
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // This can be called from system UI to add items to queue
    _logger.i('Adding item to queue: ${mediaItem.title}');
    // Implementation would depend on your specific needs
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    // This can be called from system UI to remove items from queue
    _logger.i('Removing item from queue: ${mediaItem.title}');
    // Implementation would depend on your specific needs
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < currentPlaylist.length) {
      _currentIndexSubject.add(index);
      final audio = currentPlaylist[index];
      final mediaItemData = _createMediaItem(audio);
      mediaItem.add(mediaItemData);
      
      // You would need to implement the actual audio switching logic here
      _logger.i('Skipping to queue item at index: $index');
    }
  }

  // Dispose
  void dispose() {
    _audioPlayer.dispose();
    _playlistSubject.close();
    _currentIndexSubject.close();
  }

  Duration _parseDuration(String duration) {
    // Parse duration string like "00:03:10" or "3:10"
    final parts = duration.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return Duration(minutes: minutes, seconds: seconds);
    }
    return Duration.zero;
  }


  // Enhanced media item creation helper
  MediaItem _createMediaItem(AudioModel audio) {
    return MediaItem(
      id: audio.uuid,
      album: 'Yefa Daily - Devotional Audio',
      title: audio.title,
      artist: audio.feel.isNotEmpty ? audio.feel : 'Yefa Daily',
      duration: _parseDuration(audio.length),
      // Don't set artUri - let the system use the app icon automatically
      // This prevents network errors and is more reliable
      artUri: null,
      displayTitle: audio.title,
      displaySubtitle: audio.feel.isNotEmpty ? audio.feel : 'Devotional Audio',
      displayDescription: audio.description.isNotEmpty 
        ? audio.description 
        : 'Daily spiritual audio content from Yefa Daily',
      genre: audio.genre,
      rating: const Rating.newHeartRating(true),
      extras: {
        'audioId': audio.uuid,
        'audioFeel': audio.feel,
        'audioGenre': audio.genre,
      },
    );
  }
}
