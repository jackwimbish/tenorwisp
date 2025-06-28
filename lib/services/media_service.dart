import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

// A central place for media configuration
class MediaConfig {
  static const int imageQuality = 85;
  static const int imageMaxWidth = 1080;
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB
}

class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified source, then compresses and returns it.
  /// Returns null if the user cancels the picking process.
  Future<File?> pickAndCompressImage({required ImageSource source}) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      '${pickedFile.path}_compressed.jpg',
      quality: MediaConfig.imageQuality,
      minWidth: MediaConfig.imageMaxWidth,
    );

    if (compressedFile == null) return null;

    return File(compressedFile.path);
  }

  /// Picks a video from the specified source, validates its size, then compresses it.
  /// Returns null if the user cancels, the video is too large, or compression fails.
  Future<File?> pickAndCompressVideo({
    required ImageSource source,
    required BuildContext context, // For showing SnackBars
  }) async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (pickedFile == null) return null;

    // 1. Perform client-side size check before compression
    final originalFile = File(pickedFile.path);
    final fileSize = await originalFile.length();
    if (fileSize > MediaConfig.maxVideoSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is too large (max 100MB).')),
        );
      }
      return null;
    }

    // 2. Compress the video
    final mediaInfo = await VideoCompress.compressVideo(
      originalFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false, // Keep the original in user's gallery
    );

    if (mediaInfo == null || mediaInfo.file == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to compress video.')),
        );
      }
      return null;
    }

    return mediaInfo.file;
  }
}
