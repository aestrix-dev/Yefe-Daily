import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AudioDownloadService {
  static final AudioDownloadService _instance =
      AudioDownloadService._internal();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedFiles = {};

  // Check if audio is already downloaded
  Future<bool> isAudioDownloaded(String audioId) async {
    return _downloadedFiles.containsKey(audioId);
  }

  // Get local file path if downloaded
  String? getLocalPath(String audioId) {
    return _downloadedFiles[audioId];
  }

  // Download audio file
  Future<String> downloadAudio(
    String audioId,
    String downloadUrl, {
    Function(double)? onProgress,
  }) async {
    try {
      // Check if already downloaded
      if (_downloadedFiles.containsKey(audioId)) {
        return _downloadedFiles[audioId]!;
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Create filename from audioId and URL
      final filename = '${audioId}_${_getFilenameFromUrl(downloadUrl)}';
      final filePath = '${audioDir.path}/$filename';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        _downloadedFiles[audioId] = filePath;
        return filePath;
      }

      // Download the file
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[audioId] = progress;
            onProgress?.call(progress);
          }
        },
      );

      // Store the local path
      _downloadedFiles[audioId] = filePath;
      _downloadProgress.remove(audioId);

      return filePath;
    } catch (e) {
      _downloadProgress.remove(audioId);
      throw Exception('Failed to download audio: $e');
    }
  }

  // Get download progress
  double getDownloadProgress(String audioId) {
    return _downloadProgress[audioId] ?? 0.0;
  }

  // Check if currently downloading
  bool isDownloading(String audioId) {
    return _downloadProgress.containsKey(audioId);
  }

  // Delete downloaded audio
  Future<bool> deleteDownloadedAudio(String audioId) async {
    try {
      final filePath = _downloadedFiles[audioId];
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _downloadedFiles.remove(audioId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get total downloaded files size
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    for (final filePath in _downloadedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    for (final audioId in _downloadedFiles.keys.toList()) {
      await deleteDownloadedAudio(audioId);
    }
  }

  String _getFilenameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final filename = segments.last;
      if (filename.contains('.')) {
        return filename;
      }
    }
    // Fallback: create filename from URL hash
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${digest.toString().substring(0, 8)}.mp3';
  }
}
