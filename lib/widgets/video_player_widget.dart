import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:tenorwisp/services/video_cache_service.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  final VideoCacheService _cacheService = VideoCacheService();
  late Future<void> _initializeControllerFuture;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeController();
  }

  Future<void> _initializeController() async {
    // Get the cached video file using our new service
    final File videoFile = await _cacheService.getCachedVideoFile(
      widget.videoUrl,
    );

    // Create a controller from the local file
    final videoPlayerController = VideoPlayerController.file(videoFile);

    // Initialize the controller
    await videoPlayerController.initialize();

    // Create the Chewie controller once the video is ready
    _chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: false,
      looping: false,
    );
  }

  @override
  void dispose() {
    // The ChewieController will handle disposing the VideoPlayerController
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            debugPrint("Error initializing video player: ${snapshot.error}");
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text('Could not play video.'),
                ],
              ),
            );
          }
          if (_chewieController != null) {
            return AspectRatio(
              aspectRatio:
                  _chewieController!.videoPlayerController.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
