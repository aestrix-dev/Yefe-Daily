// Example usage of the enhanced AudioPlayerService
// This demonstrates how to implement background audio with system controls

import 'package:yefa/app/app_setup.dart';
import 'package:yefa/data/services/audio_player_service.dart';
import 'package:yefa/data/models/audio_model.dart';

class AudioUsageExample {
  static final AudioPlayerService _audioService = locator<AudioPlayerService>();

  // Example: Play a single audio track with background controls
  static Future<void> playAudioWithSystemControls({
    required String audioId,
    required String title,
    required String localFilePath,
    String? feel,
    String duration = "3:00",
    String? description,
  }) async {
    try {
      // Create audio model with all required fields
      final audio = AudioModel(
        uuid: audioId,
        title: title,
        feel: feel ?? 'Devotional',
        description: description ?? 'Daily spiritual audio content',
        genre: 'Devotional',
        length: duration,
        access: 'free',
        downloadUrl: localFilePath,
      );

      // Create playlist (even for single audio)
      final playlist = [audio];
      
      // Initialize audio service if not already done
      await _audioService.initialize();
      
      // Set playlist and start playing
      // This will automatically show system controls with:
      // - Play/Pause button
      // - App icon as artwork
      // - Song title and artist
      // - Skip controls (if multiple tracks)
      await _audioService.setPlaylistAndPlay(
        playlist,
        0, // index
        localFilePath,
      );

    } catch (e) {

    }
  }

  // Example: Play a playlist with multiple tracks
  static Future<void> playPlaylist({
    required List<AudioModel> audioList,
    required List<String> localFilePaths,
    int startIndex = 0,
  }) async {
    try {
      if (audioList.isEmpty || localFilePaths.isEmpty) {
        throw Exception('Playlist cannot be empty');
      }

      if (audioList.length != localFilePaths.length) {
        throw Exception('Audio list and file paths must have same length');
      }

      // Initialize if needed
      await _audioService.initialize();
      
      // Set playlist and start playing
      await _audioService.setPlaylistAndPlay(
        audioList,
        startIndex,
        localFilePaths[startIndex],
      );

    } catch (e) {

    }
  }

  // Example: Control playback programmatically
  static Future<void> controlPlayback() async {
    // Play/Pause toggle
    await _audioService.togglePlayPause();
    
    // Skip to next track (if available)
    if (_audioService.hasNext) {
      await _audioService.playNext();
    }
    
    // Skip to previous track (if available)
    if (_audioService.hasPrevious) {
      await _audioService.playPrevious();
    }
    
    // Seek forward 10 seconds
    await _audioService.seekForwardTenSeconds();
    
    // Seek backward 10 seconds
    await _audioService.seekBackwardTenSeconds();
    
    // Stop playback completely
    await _audioService.stopPlayback();
  }

  // Example: Listen to player state changes
  static void listenToPlayerState() {
    // Listen to playlist changes
    _audioService.playlist.listen((playlist) {

    });
    
    // Listen to current track index changes
    _audioService.currentIndex.listen((index) {
      final currentTrack = _audioService.currentAudio;
      if (currentTrack != null) {

      }
    });
    
    // Listen to audio player state directly
    _audioService.audioPlayer.playerStateStream.listen((state) {

    });
    
    // Listen to position changes for progress updates
    _audioService.audioPlayer.positionStream.listen((position) {
      // Listen to position updates
    });
  }
}

/*
📱 SYSTEM INTEGRATION FEATURES:

✅ Lock Screen Controls:
   - Play/Pause button
   - Skip forward/backward (when multiple tracks)
   - Song title, artist, and album
   - App icon as artwork
   - Progress scrubber

✅ Notification Panel:
   - Rich media notification
   - Expandable controls
   - Quick actions (play, pause, skip)

✅ Hardware Integration:
   - Bluetooth headphone controls
   - Wired headphone controls
   - Car audio system integration
   - Smart watch controls

✅ Background Playback:
   - Continues playing when app is minimized
   - Survives app suspension
   - Responds to system audio interruptions
   - Proper audio session management

🔧 PLATFORM-SPECIFIC FEATURES:

iOS:
   - Control Center integration
   - CarPlay support
   - Siri integration potential
   - AirPlay support

Android:
   - Media session controls
   - Auto/Android Auto support
   - Google Assistant integration potential
   - Wear OS support
*/