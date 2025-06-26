import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheService {
  static const String cacheKey = 'videoCacheKey';

  // Set up a custom cache manager configuration.
  // This gives us control over how many videos to cache and for how long.
  static final CacheManager _cacheManager = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 7), // Cache videos for a week
      maxNrOfCacheObjects: 100, // Keep up to 100 videos in cache
    ),
  );

  /// Fetches the video file from the cache if it exists, otherwise downloads it.
  Future<File> getCachedVideoFile(String url) async {
    // First, try to get the file from the cache.
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file;
    } else {
      // If the file is not in the cache, download it.
      // The cache manager will automatically store it for next time.
      final downloadedFile = await _cacheManager.getSingleFile(url);
      return downloadedFile;
    }
  }
}
