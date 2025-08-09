import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_model.dart';

class AudioPlayerService extends BaseAudioHandler {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<List<AudioModel>> _playlistSubject =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndexSubject = BehaviorSubject.seeded(0);

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
    // Set up audio session for background play
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      // Update playback state for system media controls
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (isPlaying) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
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
          queueIndex: currentPlaylistIndex,
        ),
      );
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
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

      // Update media item for system controls
      final audio = playlist[index];
      mediaItem.add(
        MediaItem(
          id: audio.id,
          album: 'Devotional Audio',
          title: audio.title,
          artist: audio.feel,
          duration: _parseDuration(audio.duration),
          artUri: null, // You can add artwork URI here
        ),
      );

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


// Play next track
  Future<void> playNext() async {
    if (hasNext) {
      final nextIndex = currentPlaylistIndex + 1;
      _currentIndexSubject.add(nextIndex);
      // That's it! The viewmodel will handle the actual playing
    }
  }

  // Play previous track
  Future<void> playPrevious() async {
    if (hasPrevious) {
      final prevIndex = currentPlaylistIndex - 1;
      _currentIndexSubject.add(prevIndex);
      // That's it! The viewmodel will handle the actual playing
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
    return super.stop();
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
}
