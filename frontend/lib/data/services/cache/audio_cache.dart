import 'dart:convert';
import 'package:yefa/data/models/audio_model.dart';
import 'package:yefa/data/services/storage_service.dart';

// Extension for Audio caching
extension AudioCache on StorageService {
  static const String _audioListKey = 'cached_audio_list';
  static const String _audioCacheDateKey = 'audio_cache_date';

  Future<void> cacheAudioList(List<AudioModel> audios) async {
    final audiosJson = json.encode(audios.map((e) => e.toJson()).toList());
    await setString(_audioListKey, audiosJson);

    final now = DateTime.now().toIso8601String();
    await setString(_audioCacheDateKey, now);

    print('✅ Cached ${audios.length} audio items');
  }

  Future<List<AudioModel>?> getCachedAudioList() async {
    final audiosJson = getString(_audioListKey);
    final cacheDateString = getString(_audioCacheDateKey);

    if (audiosJson != null && cacheDateString != null) {
      try {
        final cacheDate = DateTime.parse(cacheDateString);
        final now = DateTime.now();

        // Check if cache is less than 4 hours old (adjust as needed)
        final difference = now.difference(cacheDate);
        if (difference.inHours < 4) {
          final List<dynamic> audiosListJson = json.decode(audiosJson);
          final cachedAudios = audiosListJson
              .map((e) => AudioModel.fromJson(e))
              .toList();

          print('✅ Loaded ${cachedAudios.length} cached audio items');
          return cachedAudios;
        } else {
          // Clear old cache
          await _clearAudioCache();
          print('⏰ Audio cache expired, cleared old data');
        }
      } catch (e) {
        print('❌ Error parsing cached audio list: $e');
        await _clearAudioCache();
      }
    }
    return null;
  }

  Future<void> _clearAudioCache() async {
    await remove(_audioListKey);
    await remove(_audioCacheDateKey);
  }

  Future<bool> hasAudioCache() async {
    return getString(_audioListKey) != null;
  }

  Future<DateTime?> getAudioCacheDate() async {
    final cacheDateString = getString(_audioCacheDateKey);
    if (cacheDateString != null) {
      try {
        return DateTime.parse(cacheDateString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear all audio-related cache
  Future<void> clearAudioCache() async {
    await _clearAudioCache();
    print('🗑️ Audio cache cleared');
  }
}
